library(readr)
library(dplyr)
library(purrr)
library(janitor)
library(duckdb)

load_garmin_hrv <- function(
    dir     = "data/garmin",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  # Garmin Connect exports HRV Status as: HRV Status_YYYY-MM-DD_YYYY-MM-DD.csv
  csv_files <- list.files(
    dir,
    pattern    = "^HRV Status.*\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) return(invisible(NULL))

  raw_data <- csv_files %>%
    map(read_csv, show_col_types = FALSE) %>%
    list_rbind() %>%
    clean_names()

  # Expected columns after clean_names():
  #   timestamp, hrv_status, weekly_average_hrv,
  #   last_nights_5_minute_hrv, last_nights_average_hrv,
  #   last_nights_low_hrv,
  #   last_nights_baseline_low_upper,
  #   last_nights_baseline_balanced_lower,
  #   last_nights_baseline_balanced_upper
  daily_data <- raw_data %>%
    mutate(date = as.Date(substr(timestamp, 1, 10))) %>%
    summarise(
      .by = date,
      garmin_hrv_weekly_avg    = mean(weekly_average_hrv,         na.rm = TRUE),
      garmin_hrv_last_night    = mean(last_nights_average_hrv,    na.rm = TRUE),
      garmin_hrv_last_night_5m = mean(last_nights_5_minute_hrv,   na.rm = TRUE),
      garmin_hrv_last_night_lo = mean(last_nights_low_hrv,        na.rm = TRUE),
      garmin_hrv_status        = first(hrv_status)
    ) %>%
    arrange(date)

  DBI::dbWriteTable(con, "garmin_hrv_daily", daily_data, overwrite = TRUE)
  message("\u2713 garmin_hrv_daily written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

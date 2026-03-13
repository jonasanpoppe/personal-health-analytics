library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(duckdb)

load_rhr <- function(
    dir = "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Physical Activity_GoogleData",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  csv_files <- list.files(
    dir,
    pattern    = "^daily_resting_heart_rate\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) return(invisible(NULL))

  raw_data <- csv_files %>%
    map(read_csv, show_col_types = FALSE) %>%
    list_rbind() %>%
    clean_names()

  daily_data <- raw_data %>%
    mutate(date = as.Date(substr(timestamp, 1, 10))) %>%
    rename(resting_heart_rate = beats_per_minute) %>%
    select(date, resting_heart_rate) %>%
    arrange(date)

  DBI::dbWriteTable(con, "fitbit_rhr_daily", daily_data, overwrite = TRUE)
  message("\u2713 fitbit_rhr_daily written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

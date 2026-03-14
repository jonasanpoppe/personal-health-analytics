library(jsonlite)
library(dplyr)
library(purrr)
library(duckdb)

load_garmin_api <- function(
    dir     = "data/garmin_api",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  json_files <- list.files(
    dir,
    pattern    = "_garmin_api\\.json$",
    full.names = TRUE
  )

  if (length(json_files) == 0) return(invisible(NULL))

  daily_data <- json_files %>%
    map(fromJSON) %>%
    list_rbind() %>%
    mutate(date = as.Date(date)) %>%
    # Collapse duplicates in case of overlapping fetches — keep non-NA values
    summarise(
      .by = date,
      rhr                    = first(na.omit(rhr)),
      hrv                    = first(na.omit(hrv)),
      hrv_last_night         = first(na.omit(hrv_last_night)),
      hrv_last_night_avg     = first(na.omit(hrv_last_night_avg)),
      hrv_last_night_5_min_high = first(na.omit(hrv_last_night_5_min_high)),
      hrv_baseline_low       = first(na.omit(hrv_baseline_low)),
      hrv_baseline_high      = first(na.omit(hrv_baseline_high)),
      hrv_status             = first(na.omit(hrv_status))
    ) %>%
    arrange(date)

  DBI::dbWriteTable(con, "garmin_api_daily", daily_data, overwrite = TRUE)
  message("garmin_api_daily written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

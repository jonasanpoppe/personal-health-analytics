library(jsonlite)
library(dplyr)
library(purrr)
library(duckdb)

load_garmin_wellness <- function(
    dir     = "data/raw_data/da0779f1-f01f-45e6-865a-e08f44f45e3c_1/DI_CONNECT/DI-Connect-Wellness",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  json_files <- list.files(
    dir,
    pattern    = "healthStatusData\\.json$",
    full.names = TRUE
  )

  if (length(json_files) == 0) return(invisible(NULL))

  raw_data <- json_files %>%
    map(fromJSON) %>%
    list_rbind()

  # Each row has calendarDate and a metrics list-column containing typed entries
  daily_data <- raw_data %>%
    mutate(
      date = as.Date(calendarDate),
      rhr  = map_dbl(metrics, \(m) {
        val <- m$value[m$type == "HR"]
        if (length(val) == 0) NA_real_ else val[1]
      }),
      hrv  = map_dbl(metrics, \(m) {
        val <- m$value[m$type == "HRV"]
        if (length(val) == 0) NA_real_ else val[1]
      }),
      hrv_baseline_low = map_dbl(metrics, \(m) {
        val <- m$baselineLowerLimit[m$type == "HRV"]
        if (length(val) == 0) NA_real_ else val[1]
      }),
      hrv_baseline_high = map_dbl(metrics, \(m) {
        val <- m$baselineUpperLimit[m$type == "HRV"]
        if (length(val) == 0) NA_real_ else val[1]
      }),
      hrv_status = map_chr(metrics, \(m) {
        val <- m$status[m$type == "HRV"]
        if (length(val) == 0) NA_character_ else val[1]
      })
    ) %>%
    select(date, rhr, hrv, hrv_baseline_low, hrv_baseline_high, hrv_status) %>%
    arrange(date)

  DBI::dbWriteTable(con, "garmin_wellness_daily", daily_data, overwrite = TRUE)
  message("\u2713 garmin_wellness_daily written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

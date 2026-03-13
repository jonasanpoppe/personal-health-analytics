library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(duckdb)

load_temperature <- function(
    dir = "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Physical Activity_GoogleData",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  csv_files <- list.files(
    dir,
    pattern    = "^daily_sleep_temperature_derivations.*\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) return(invisible(NULL))

  raw_data <- csv_files %>%
    map(read_csv, show_col_types = FALSE) %>%
    list_rbind() %>%
    clean_names()

  # Note: The column is "nightly temperature celsius" -> nightly_temperature_celsius
  daily_data <- raw_data %>%
    mutate(date = as.Date(substr(timestamp, 1, 10))) %>%
    summarise(
      .by = date,
      temperature_celsius = mean(nightly_temperature_celsius, na.rm = TRUE)
    ) %>%
    arrange(date)

  DBI::dbWriteTable(con, "fitbit_temperature_nightly", daily_data, overwrite = TRUE)
  message("\u2713 fitbit_temperature_nightly written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

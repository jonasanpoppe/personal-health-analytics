library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(duckdb)

load_readiness <- function(
    dir = "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Daily Readiness",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  csv_files <- list.files(
    dir,
    pattern    = "^Daily Readiness Score.*\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) return(invisible(NULL))

  raw_data <- csv_files %>%
    map(read_csv, show_col_types = FALSE) %>%
    list_rbind() %>%
    clean_names()

  daily_data <- raw_data %>%
    mutate(date = as.Date(date)) %>%
    summarise(
      .by = date,
      readiness_score = mean(readiness_score_value, na.rm = TRUE)
    ) %>%
    arrange(date)

  DBI::dbWriteTable(con, "fitbit_readiness_daily", daily_data, overwrite = TRUE)
  message("\u2713 fitbit_readiness_daily written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

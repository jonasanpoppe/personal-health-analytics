library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(duckdb)

load_sleep_score <- function(
    dir = "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Health Fitness Data_GoogleData",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  csv_files <- list.files(
    dir,
    pattern    = "^UserSleepScores_.*\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) return(invisible(NULL))

  raw_data <- csv_files %>%
    map(read_csv, show_col_types = FALSE) %>%
    list_rbind() %>%
    clean_names()

  daily_data <- raw_data %>%
    mutate(date = as.Date(substr(score_time, 1, 10))) %>%
    summarise(
      .by = date,
      sleep_score = mean(overall_score, na.rm = TRUE),
      sleep_duration_score = mean(duration_score, na.rm = TRUE),
      sleep_composition_score = mean(composition_score, na.rm = TRUE),
      sleep_revitalization_score = mean(revitalization_score, na.rm = TRUE)
    ) %>%
    arrange(date)

  DBI::dbWriteTable(con, "fitbit_sleep_score", daily_data, overwrite = TRUE)
  message("\u2713 fitbit_sleep_score written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(duckdb)

load_stress_score <- function(
    dir = "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Stress Score",
    db_path = "db/health.db"
) {
  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  csv_files <- list.files(
    dir,
    pattern    = "^Stress Score\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) return(invisible(NULL))

  raw_data <- csv_files %>%
    map(read_csv, show_col_types = FALSE) %>%
    list_rbind() %>%
    clean_names()

  daily_data <- raw_data %>%
    mutate(date = as.Date(substr(date, 1, 10))) %>%
    summarise(
      .by = date,
      stress_score = mean(stress_score, na.rm = TRUE)
    ) %>%
    arrange(date)

  DBI::dbWriteTable(con, "fitbit_stress_score", daily_data, overwrite = TRUE)
  message("\u2713 fitbit_stress_score written (", nrow(daily_data), " rows)")

  invisible(daily_data)
}

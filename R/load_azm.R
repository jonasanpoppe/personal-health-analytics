library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)
library(duckdb)

load_azm <- function(
    azm_dir = "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Active Zone Minutes (AZM)",
    db_path = "db/health.db"
) {

  con <- DBI::dbConnect(duckdb(), db_path)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  # 1. List all AZM CSVs (exclude Zone.Identifier files)
  csv_files <- list.files(
    azm_dir,
    pattern    = "^Active Zone Minutes.*\\.csv$",
    full.names = TRUE
  )

  if (length(csv_files) == 0) {
    stop("No AZM CSV files found in: ", azm_dir)
  }

  # 2. Read & bind all files
  azm_raw <- csv_files |>
    map(read_csv, show_col_types = FALSE) |>
```r
    list_rbind() %>%
```
    clean_names()

  # 3. Parse datetime, extract date
  azm_raw <- azm_raw |>
    mutate(
      date_time = as.POSIXct(date_time, format = "%Y-%m-%dT%H:%M"),
      date      = as.Date(date_time)
    )

  # 4. Aggregate to daily grain, pivoted by zone

  azm_daily <- azm_raw |>
    summarise(
      .by           = c(date, heart_zone_id),
      total_minutes = sum(total_minutes)
    ) |>
    pivot_wider(
      names_from   = heart_zone_id,
      values_from  = total_minutes,
      values_fill  = 0,
      names_prefix = "azm_"
    ) |>
    clean_names() |>
    mutate(azm_total = rowSums(pick(starts_with("azm_")))) |>
    arrange(date)

  # 5. Write to DuckDB
  DBI::dbWriteTable(con, "fitbit_azm_daily", azm_daily, overwrite = TRUE)
  message("✓ fitbit_azm_daily written (", nrow(azm_daily), " rows)")

  invisible(azm_daily)
}

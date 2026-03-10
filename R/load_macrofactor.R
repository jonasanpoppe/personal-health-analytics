library(readxl)
library(duckdb)
library(dplyr)
library(tidyr)
library(purrr)
library(janitor)

load_macrofactor <- function(
    path = "data/raw_data/MacroFactor-20260310221353.xlsx",
    db_path = "db/health.db"
) {

  con <- dbConnect(duckdb(), db_path)
  on.exit(dbDisconnect(con, shutdown = TRUE))

  # ── Daily tables ────────────────────────────────────────────────────────────
  daily_sheets <- c(
    "Calories & Macros",
    "Micronutrients",
    "Scale Weight",
    "Body Metrics",
    "Weight Trend",
    "Expenditure",
    "Steps"
  )

  daily_df <- daily_sheets %>%
    map(function(sheet) {
      read_excel(path, sheet = sheet) %>%
        clean_names() %>%
        mutate(date = as.Date(date))
    }) %>%
    reduce(full_join, by = "date") |>
    arrange(date)

  dbWriteTable(con, "macrofactor_daily", daily_df, overwrite = TRUE)
  message("✓ macrofactor_daily written (", nrow(daily_df), " rows)")

  # ── Exercise tables ──────────────────────────────────────────────────────────
  exercise_sheets <- c(
    "Muscle Groups - Sets",
    "Muscle Groups - Volume",
    "Exercises - 1-RM",
    "Exercises - 3-RM",
    "Exercises - 10-RM",
    "Exercises - Total Volume",
    "Exercises - Best Set Volume",
    "Exercises - Heaviest Weight",
    "Exercises - Total Reps",
    "Exercises - Best Set Reps",
    "Exercises - Total Sets"
  )

  exercise_df <- exercise_sheets |>
    map(function(sheet) {
      metric_name <- sheet |>
        str_remove("^(Exercises|Muscle Groups) - ") |>
        make_clean_names()

      read_excel(path, sheet = sheet) |>
        clean_names() |>
        mutate(date = as.Date(date)) |>
        pivot_longer(
          cols      = -date,
          names_to  = "exercise",
          values_to = metric_name
        )
    }) |>
    reduce(full_join, by = c("date", "exercise")) |>
    arrange(date, exercise)

  dbWriteTable(con, "macrofactor_exercise", exercise_df, overwrite = TRUE)
  message("✓ macrofactor_exercise written (", nrow(exercise_df), " rows)")

  invisible(list(
    daily    = daily_df,
    exercise = exercise_df
  ))
}

library(targets)
library(tarchetypes)

# Load all functions from R/
tar_source("R/")

# Pipeline options
tar_option_set(
  packages = c("readxl", "duckdb", "dplyr", "tidyr", "purrr", "janitor", "stringr")
)

list(

  # ── Source file tracking ─────────────────────────────────────────────────────
  # Targets will re-run downstream steps if these files change
  tar_target(macrofactor_file, "data/raw_data/MacroFactor-20260310221353.xlsx", format = "file"),
  # Future sources:
  # tar_target(garmin_dir,       "data/garmin/",          format = "file"),
  # tar_target(strava_file,      "data/strava.csv",       format = "file"),

  # ── Load raw data ────────────────────────────────────────────────────────────
  tar_target(
    macrofactor_raw,
    load_macrofactor(
      path    = macrofactor_file,
      db_path = "db/health.db"
    )
  ),
  # Future loaders:
  # tar_target(garmin_raw,   load_garmin(garmin_dir)),
  # tar_target(strava_raw,   load_strava(strava_file)),

  # ── Clean ───────────────────────────────────────────────────────────────────
  tar_target(
    macrofactor_daily,
    macrofactor_raw$daily
  ),
  tar_target(
    macrofactor_exercise,
    macrofactor_raw$exercise
  ),
  # Future:
  # tar_target(garmin_clean,  clean_garmin(garmin_raw)),
  # tar_target(strava_clean,  clean_strava(strava_raw)),

  # ── Join ─────────────────────────────────────────────────────────────────────
  # Placeholder: extend as new daily-grain sources are added
  tar_target(
    daily,
    macrofactor_daily
    # Future: reduce(full_join, by = "date") across all daily-grain sources
  )

)




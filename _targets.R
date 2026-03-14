library(targets)
library(tarchetypes)

# Load all functions from R/
tar_source("R/")

# Pipeline options
tar_option_set(
  packages = c("readr", "readxl", "jsonlite", "duckdb", "dplyr", "tidyr", "purrr", "janitor", "stringr")
)

list(

  # ── Source file tracking ─────────────────────────────────────────────────────
  # Targets will re-run downstream steps if these files change
  tar_target(macrofactor_file, "data/raw_data/MacroFactor-20260310221353.xlsx", format = "file"),
  tar_target(azm_dir, "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Active Zone Minutes (AZM)", format = "file"),
  tar_target(physical_activity_dir, "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Physical Activity_GoogleData", format = "file"),
  tar_target(readiness_dir, "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Daily Readiness", format = "file"),
  tar_target(sleep_score_dir, "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Health Fitness Data_GoogleData", format = "file"),
  tar_target(stress_score_dir, "data/raw_data/takeout-20260310T172133Z-3-001/Takeout/Fitbit/Stress Score", format = "file"),
  tar_target(garmin_wellness_dir, "data/raw_data/da0779f1-f01f-45e6-865a-e08f44f45e3c_1/DI_CONNECT/DI-Connect-Wellness", format = "file"),
  # Future sources:
  # tar_target(strava_file, "data/strava.csv", format = "file"),

  # ── Load raw data ────────────────────────────────────────────────────────────
  tar_target(
    macrofactor_raw,
    load_macrofactor(
      path    = macrofactor_file,
      db_path = "db/health.db"
    )
  ),
  tar_target(
    azm_daily,
    load_azm(azm_dir = azm_dir, db_path = "db/health.db")
  ),
  tar_target(
    steps_daily,
    load_steps(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    distance_daily,
    load_distance(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    calories_daily,
    load_calories(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    hrv_daily,
    load_hrv(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    rr_daily,
    load_rr(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    spo2_daily,
    load_spo2(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    temperature_daily,
    load_temperature(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    readiness_daily,
    load_readiness(dir = readiness_dir, db_path = "db/health.db")
  ),
  tar_target(
    sleep_score_daily,
    load_sleep_score(dir = sleep_score_dir, db_path = "db/health.db")
  ),
  tar_target(
    stress_score_daily,
    load_stress_score(dir = stress_score_dir, db_path = "db/health.db")
  ),
  tar_target(
    rhr_daily,
    load_rhr(dir = physical_activity_dir, db_path = "db/health.db")
  ),
  tar_target(
    garmin_wellness_daily,
    load_garmin_wellness(dir = garmin_wellness_dir, db_path = "db/health.db")
  ),
  # Future loaders:
  # tar_target(strava_raw, load_strava(strava_file)),

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
  # tar_target(strava_clean, clean_strava(strava_raw)),

  # ── Join ─────────────────────────────────────────────────────────────────────
  # Placeholder: extend as new daily-grain sources are added
  tar_target(
    daily,
    macrofactor_daily %>%
      full_join(azm_daily, by = "date") %>%
      full_join(steps_daily, by = "date") %>%
      full_join(distance_daily, by = "date") %>%
      full_join(calories_daily, by = "date") %>%
      full_join(hrv_daily, by = "date") %>%
      full_join(rr_daily, by = "date") %>%
      full_join(spo2_daily, by = "date") %>%
      full_join(temperature_daily, by = "date") %>%
      full_join(readiness_daily, by = "date") %>%
      full_join(sleep_score_daily, by = "date") %>%
      full_join(stress_score_daily, by = "date") %>%
      full_join(rhr_daily, by = "date") %>%
      full_join(garmin_wellness_daily, by = "date")
  )

)




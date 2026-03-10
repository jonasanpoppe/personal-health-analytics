# Initialize DuckDB for health-dashboard

# Check if packages are installed, if not, wait or stop clearly if run manually
if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
  stop("DBI and duckdb packages are required. Please install them first.")
}

library(DBI)
library(duckdb)
library(readxl)
library(janitor)

# Ensure Data directory exists
if (!dir.exists("Data")) {
  dir.create("Data")
}

macrofactor_data <- "Data/raw_data/MacroFactor-20260310221353.xlsx"
macrofactor_db <-

# Connect to the database (creates it if it doesn't exist)
con <- dbConnect(duckdb::duckdb(), dbdir = "Data/macrofactor_raw.duckdb")
sheets <- excel_sheets(macrofactor_data)

make_clean_names(sheets[[4]])

for (sheet in sheets) {
  df <- read_excel(macrofactor_data, sheet = sheet)
  dbWriteTable(con, paste0("macrofactor_", make_clean_names(sheet), "_raw"), df, overwrite = TRUE)
}

dbExecute(con, "
CREATE VIEW daily AS
SELECT
    COALESCE(c.Date, w.Date) as date,
    c.\"Calories (kcal)\"   as calories_kcal,
    c.\"Fat (g)\"           as fat_g,
    c.\"Carbs (g)\"         as carbs_g,
    c.\"Protein (g)\"       as protein_g,
    w.\"Trend Weight (kg)\"  as trend_weight_kg
FROM macrofactor_calories_macros_raw c
FULL JOIN macrofactor_weight_trend_raw w ON c.Date = w.Date
")

dbGetQuery(con, "SELECT * FROM daily LIMIT 5")

dbGetQuery(con, "SELECT * FROM macrofactor_exercises_1_rm_raw LIMIT 5")


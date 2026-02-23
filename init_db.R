# Initialize DuckDB for SEC-dashboard

# Check if packages are installed, if not, wait or stop clearly if run manually
if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
  stop("DBI and duckdb packages are required. Please install them first.")
}

library(DBI)
library(duckdb)

# Ensure Data directory exists
if (!dir.exists("Data")) {
  dir.create("Data")
}

# Connect to the database (creates it if it doesn't exist)
con <- dbConnect(duckdb::duckdb(), dbdir = "Data/sec_dashboard.duckdb")

# Create a sample table if it doesn't exist
if (!dbExistsTable(con, "metrics")) {
  message("Creating 'metrics' table...")
  
  # Sample data
  metrics_data <- data.frame(
    timestamp = seq(as.POSIXct("2023-01-01"), as.POSIXct("2023-01-10"), by = "day"),
    value = runif(10, min = 10, max = 100),
    category = sample(c("A", "B", "C"), 10, replace = TRUE)
  )
  
  dbWriteTable(con, "metrics", metrics_data)
  message("Table 'metrics' created with ", nrow(metrics_data), " rows.")
} else {
  message("Table 'metrics' already exists.")
}

# List tables to verify
print(dbListTables(con))

# Disconnect
dbDisconnect(con, shutdown = TRUE)
message("Database initialization complete.")

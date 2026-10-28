# =============================================================
# GTVET-IDMS  Export institution list to CSV
# Run from app/ directory:
#   Rscript ../db/admin/export_institutions.R
# Or paste into R console while the app is running
# =============================================================

library(pool)
library(DBI)

# --- Connection (edit if your settings differ) ----------------
host <- Sys.getenv("GTVET_DB_HOST",     "localhost")
port <- Sys.getenv("GTVET_DB_PORT",     "5432")
name <- Sys.getenv("GTVET_DB_NAME",     "gtvet")
user <- Sys.getenv("GTVET_DB_USER",     "postgres")
pass <- Sys.getenv("GTVET_DB_PASSWORD", "")

con <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = host, port = as.integer(port),
  dbname = name, user = user, password = pass
)

# --- Query all institutions -----------------------------------
all_institutions <- DBI::dbGetQuery(con, "
  SELECT
    i.institution_id,
    i.institution_name,
    i.cssps_code,
    r.region_name,
    d.district_name,
    i.location,
    i.institution_type,
    i.gender_type,
    i.is_active,
    i.created_at::date AS date_added
  FROM institutions i
  JOIN regions r ON r.region_id = i.region_id
  LEFT JOIN districts d ON d.district_id = i.district_id
  ORDER BY r.region_name, i.institution_name
")

cat("Total institutions in database:", nrow(all_institutions), "\n")

# --- Export to CSV -------------------------------------------
out_file <- file.path(getwd(), "institutions_full_list.csv")
write.csv(all_institutions, out_file, row.names = FALSE)
cat("Saved:", out_file, "\n")

# --- Find duplicates -----------------------------------------
cat("\n=== Duplicate names ===\n")
dup_names <- all_institutions[
  duplicated(tolower(trimws(all_institutions$institution_name))) |
  duplicated(tolower(trimws(all_institutions$institution_name)), fromLast = TRUE), ]
if (nrow(dup_names) > 0) {
  print(dup_names[, c("institution_id","institution_name","cssps_code","region_name","district_name")])
} else {
  cat("None found by exact name match.\n")
}

cat("\n=== Duplicate CSSPS codes ===\n")
codes_only <- all_institutions[!is.na(all_institutions$cssps_code), ]
dup_codes <- codes_only[
  duplicated(codes_only$cssps_code) |
  duplicated(codes_only$cssps_code, fromLast = TRUE), ]
if (nrow(dup_codes) > 0) {
  print(dup_codes[, c("institution_id","institution_name","cssps_code","region_name")])
} else {
  cat("None found.\n")
}

cat("\n=== Institutions with NULL CSSPS code ===\n")
null_codes <- all_institutions[is.na(all_institutions$cssps_code), ]
cat("Count:", nrow(null_codes), "\n")
if (nrow(null_codes) > 0) {
  print(null_codes[, c("institution_id","institution_name","region_name","district_name","date_added")])
}

DBI::dbDisconnect(con)
cat("\nDone.\n")

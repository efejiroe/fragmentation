rm(list = ls())

# ETL
# Extraction, Transform and Load
source('ini.R')
tic(msg = "ETL")

# Extraction ----

d <- read_excel("data/extracts.xlsx", sheet = "20250828")|>clean_names()|>setDT()

# Review 
schema <- head(d, 5)
fwrite(schema, 'data/schema.csv')

summary_text <- capture.output(print(skim(d)))
writeLines(summary_text, con = paste0('data/data-summary.txt'))

# Transformations
d[, ID := .I] # Indexing
d[, imd_decile_number := as.character(imd_decile_number)] # Convert IMD to character

# TFC
tfcs_tbl <-  read_excel("data/Included TFCs.xlsx")|>clean_names()|>setDT()
tfcs_cols <- unique(tfcs_tbl$tfc)

d[, distinct_combos_first_5 := sapply(
  strsplit(as.character(list_of_provider_site_tfc_combos), "[\r\n]+"),
  function(x) uniqueN(head(x, 5))
  )]

d[, paste0('tfc_visit_', 1:5) := tstrsplit(
  as.character(list_of_tfcs),
  split = '[\r\n]+',
  keep = 1:5
  )] # First to fifth specialist visit

d[, (tfcs_cols) := lapply(tfcs_cols, function(x) { # TFC Column count
  stringr::str_count(list_of_tfcs, paste0("\\b", x, "\\b"))   # Boundary \b 
})]

d[, total_tfcs := rowSums(.SD), .SDcols = tfcs_cols]

service_cols <- grep("service", names(d), value = TRUE, ignore.case = TRUE)
clean_service_cols <- make_clean_names(service_cols)
setnames(d, old = service_cols, new = clean_service_cols)

# Save TFC lookup
useCols <- c('ID', clean_service_cols)

tfcs <- d[, ..useCols]

saveRDS(tfcs, 'data/tfcs.RDS')

rm(tfcs)

# Sub-setting
useCols <- c(
  "ID",
  
  # Patient Characteristics
  "patient_group",
  "imd_decile_number",
  "ethnic_broad_group_name",
  "age_band_name",
  "gender_name",
  "total_ltc",
  
  # Outcome
  "nel_admissions",
  "ed_attendances",
  
  # Patient Admin
  "number_of_dnas",
  "total_bookings",
  "total_bed_days",
  
  # Indices 
  "fci_by_provider_site_tfc",
  "secon_by_provider_site_tfc",
  
  # Service
  "number_of_providers",
  "number_of_provider_sites",
  "list_of_tfcs",
  "number_of_tfcs",
  "total_tfcs",
  "number_of_provider_site_tfc_combos",
  "tfc_visit_1",
  "distinct_combos_first_5"
  
)

c <- d[, ..useCols]

# Exclusion Criteria
# 4 Cancer and 1 Renal services skew FCI
# Defines "avoidable fragmentation in complex patients cohorts"
# Are there others?

c[, tfc_exclusion := grepl("(?i)oncology|renal", list_of_tfcs)]
c <- c[tfc_exclusion == F,] # Analysis data without cancer and renal patients.
c[,tfc_exclusion := NULL]

c[,list_of_tfcs := NULL]
 
# message(nrow(d)-nrow(c), paste0(" Complex patients with unavoidable fragmentation removed."))

saveRDS(c, 'data/subset.RDS')

# Clean up environment
toc()

rm(list = ls())

source('etl.R')

# Raw data
skim(d)
skim(c)

# 1. Does missing IMD bias groups? ----
# Ethnicity
tabyl(d$ethnic_broad_group_name)
tabyl(d[!is.na(imd_decile_number),]$ethnic_broad_group_name)

# Patient Group
tabyl(d$patient_group)
tabyl(d[!is.na(imd_decile_number),]$patient_group)


# 2. Does Cancer and Renal skew FCI? ----
d[, tfc_exclusion := grepl("(?i)oncology|renal", list_of_tfcs)]
mean(d[tfc_exclusion == T]$fci_by_provider_site_tfc) # Renal and Cancer
mean(d[tfc_exclusion == F]$fci_by_provider_site_tfc) # others


# TFC transformation test ----
dt <- data.table(
  patient_id = 1:3,
  list_of_tfcs = c("100, 101, 100", "101, 300", "100")
)

unique_tfcs <- c("100", "101", "300", "400")

dt[, (unique_tfcs) := lapply(unique_tfcs, function(x) {
  # Boundary \b ensures '100' doesn't match '1000'
  str_count(list_of_tfcs, paste0("\\b", x, "\\b"))
})]


d[, unique_tfc_count := rowSums(.SD > 0, na.rm = TRUE), .SDcols = cols]
# "number_of_tfcs" approximates to this


# Join TFC count data
if(skip == TRUE){
  tfcs <- readRDS('data/tfcs.RDS')
  d <- merge(d, tfcs, by = 'ID')
}

charvars <- names(d)[sapply(d, is.character)]
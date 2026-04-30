rm(list = ls())

source('ini.R')
skip <- TRUE
tic(msg = "EDA: Economics")

# 10% reduction in redundant appointments for High-Fragmentation cohort (FCI > 0.80)

# Load cleaned subset
d <- readRDS('data/subset.RDS')

# Unit Cost
# Health Economist Estimate
outpatient_gbp <- 198

# Define High Fragmentation Cohort (The "Nomad" Threshold)
d[, cohort := ifelse(fci_by_provider_site_tfc > 0.75, "High Fragmentation (>0.75)", "Stable (<0.75)")]

# Calculate Baseline Financials
fin_summary <- d[, .(
  patient_count = .N,
  total_appointments = sum(total_bookings, na.rm = TRUE),
  avg_appts_per_patient = mean(total_bookings, na.rm = TRUE),
  total_cost_gbp = sum(total_bookings, na.rm = TRUE) * outpatient_gbp
), by = cohort]

# Calculate Potential Savings (10% Reduction Goal)
fin_summary[, potential_saving_10pct := ifelse(cohort == "High Fragmentation (>0.75)", total_cost_gbp * 0.10, 0)]

# Add Totals
total_row <- data.table(
  cohort = "Total System",
  patient_count = nrow(d),
  total_appointments = sum(d$total_bookings),
  avg_appts_per_patient = mean(d$total_bookings),
  total_cost_gbp = sum(d$total_bookings) * UNIT_COST_OP,
  potential_saving_10pct = sum(fin_summary$potential_saving_10pct)
)

fin_output <- rbind(fin_summary, total_row)

# Format for display
fin_output[, total_cost_m := total_cost_gbp / 1e6]
fin_output[, potential_saving_k := potential_saving_10pct / 1e3]

print(fin_output)

# Save result
fwrite(fin_output, 'data/fin_summary.csv')

message("10% of High FCI cohort savings: £", round(total_row$potential_saving_10pct / 1e3, 0), "K\n") # 10% of cohort will save £6 million


toc()

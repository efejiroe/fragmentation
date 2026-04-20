rm(list = ls())

source('ini.R')
skip <- TRUE
tic(msg = "EDA: Regression Analysis 2")

# What lead or Lag metric predicts FCI?
# Ideally, we want the metric to be caught earlier in a patients journey.

d <- readRDS('data/subset.RDS')

# Transformation
d[, dna_rate := number_of_dnas/total_bookings]

delCols <- c(
  'ID'
  ,'patient_group' # We got age and LT count already.
  ,'total_bookings'
  ,'number_of_dnas' # DNA rates instead
  
  # Lag indicators
  ,'nel_admissions'
  ,'total_bed_days'
  ,'ed_attendances'
  ,'total_tfcs'
  ,'number_of_tfcs'
  ,'number_of_provider_site_tfc_combos'
  ,'number_of_providers'
  ,'number_of_provider_sites'
  ,'secon_by_provider_site_tfc'
)

m <- d[, !..delCols]

m <- na.omit(m)

sample_prop <- 0.99 # adjust for quicker runs
m <- m[sample(.N, .N * sample_prop)] 

message(paste0('Sample size: ', nrow(m)))

cat("Use Columns: \n")
as.matrix(names(m))

# Set factors and reference groups
m$ethnic_broad_group_name <- relevel(as.factor(m$ethnic_broad_group_name), ref = "White")
m$imd_decile_number <- relevel(as.factor(m$imd_decile_number), ref = "10")

# Regressions to find association
targets <- c('fci_by_provider_site_tfc')

# Learner list
mlr_learners$keys()

for(target in targets){
  
  Learning_task = as_task_regr(
    m, 
    target = target,
    id = "Fragmentation Regression"
  )
  
  # 1. Random forest/X-boost and tipping point
  learner_rf = lrn("regr.ranger", importance = "permutation")
  learner_rf$train(Learning_task)
  
  # Save importance
  importance_scores <- learner_rf$importance()
  importance_tbl <- data.table(
    features = names(importance_scores),
    scores = as.numeric(importance_scores)
  )
  
  fwrite(importance_tbl, paste0('data/importance_',target,'.csv'))
  message <- paste0("RF feature importance for ",target," saved.\n")
  cat(message)
  
  # Generate s-curve (Partial Dependence)
  if(skip == FALSE){
    predictor = Predictor$new(learner_rf, data = m, y = target)
    pdp = FeatureEffect$new(predictor, feature = "fci_by_provider_site_tfc", method = "pdp")
    fwrite(pdp$results, paste0('data/pdp_', target, '.csv'))
  }
  
  # 2. Poisson/NB since the outcomes are counting data
  # Scaling not needed
  formula_str <- as.formula(paste(target, "~ ."))
  poisson_model <- glm(formula_str, data = m, family = poisson)
  
  # Save GLM summary
  summary_text <- capture.output(print(summary(poisson_model)))
  writeLines(summary_text, con = paste0('data/glm_',target,'.txt'))
  message <- paste0("GLM summary for ",target," saved.\n")
  cat(message)
  
  # Dispersion Diagnostics
  # Visually, the plots suggest minimal dispersion 
  # However, 200k is a large sample size (overpowered) with p always being 0.
  simulationOutput <- simulateResiduals(fittedModel = poisson_model)
  
  pdf(paste0("img/dharma_diagnostic_",target,".pdf"), width = 10, height = 7)
  plot(simulationOutput)
  dev.off()
  
  png(paste0("img/dharma_test_",target,".png"), width = 800, height = 600)
  testDispersion(simulationOutput)
  
  dev.off()
} 
toc() # How Long?

# What this tells us:

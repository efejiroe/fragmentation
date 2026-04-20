rm(list = ls())

source('ini.R')
skip <- TRUE
tic(msg = "EDA: Cluster Analysis")

# There is little differentiation between the defined patient groups.
# Cluster analysis organises diverse data into distinct groups to create actionable behavioural profiles.
# It also exposes hidden heterogeneity and reduces dimensionality.

d <- readRDS('data/subset.RDS')

charvars <- names(d)[sapply(d, is.character)]

delCols <- c(
  'ID',
  charvars
)

m <- d[, !..delCols]

cat("Use Columns: \n")
as.matrix(names(m))

cluster_task <- as_task_clust(
  m,
  id = "Fragementation Clustering"
  )
learner_km =lrn('clust.kmeans', centers = 3) # What informed this?

# Sampling for training
set.seed(123)
perc <- 0.25
sample_size <- floor(cluster_task$nrow * perc)

sample_task = cluster_task$clone()$filter(sample(seq_len(cluster_task$nrow), sample_size))

learner_km$train(sample_task) # training
prediction = learner_km$predict(sample_task) # Assign clusters

# Cluster Silhouette Evaluation
measure = msr("clust.silhouette")
message("Validation Score: ", prediction$score(measure, task = sample_task))

# Assign cluster to full data
cluster_model = learner_km$predict(cluster_task)
clusters_tbl <- as.data.table(cluster_model)

d[, link_id := as.integer(rownames(d))]
d[clusters_tbl, cluster_id := partition, on = .(link_id = row_ids)]


# Cluster analysis
tbl <- d[, .(
   N = .N,
   # Fragmentation metrics
   avg_fci = mean(fci_by_provider_site_tfc),
   avg_secon = mean(secon_by_provider_site_tfc), # Essential for Nomad identification (sequential continuity)
   avg_ltc = mean(total_ltc), # Patient Characteristics
   # Outcome metrics
   avg_dna = mean(number_of_dnas)/mean(total_bookings), # Patient Behaviour
   avg_ed = mean(ed_attendances),
   avq_nel = mean(nel_admissions),
   ave_stay = mean(total_bed_days)
   
   # Demographics
   
 ), by = cluster_id]

fwrite(tbl, 'data/cluster_analysis.csv')

# Hypothetical profiles
# Clusters 1: The high-utility navigators
# Cluster 2: The fragile crisis cohort
# Cluster 3: The low complexity nomads

# Save Clusters lookup
saveRDS(d[, c('ID', 'cluster_id')], 'data/clusters.RDS')

toc()

# What this tells us:
# I can only build clusters with numerical data.
# K = 3 has a better validation score than 4 (55 v 46) i.e., more distinct groups.
# The 3 groups are distinct (FCI = 63, 59 and 41)
# The 3 groups seem to be defined by the number of complexities 3, 4 and more with the middle showing the highest fragmentation
# How do I profile them? How do I study them further in line with goals?
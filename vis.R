rm(list = ls())

source('ini.R')
skip <- TRUE
tic(msg = "VIS: Facts Output")

d <- readRDS('data/subset.RDS')

clusters <- readRDS('data/clusters.RDS')

d[clusters, cluster_id := i.cluster_id, on = .(ID)]

fwrite(d, 'data/facts.csv')

toc()
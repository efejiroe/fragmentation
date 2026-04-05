# INITIALISATION
# Load, environment variables, packages and custom functions,

## Environment variables ----
# Portable Git PATH
Sys.setenv(PATH = paste("C:/Users/EfejiroAshano(NHSSou/OneDrive - SE London ICB/Documents/PortableGit/bin", Sys.getenv("PATH"), sep = ";"))

## Packages ----
if(!require('pacman')){
  install.packages('pacman')
}

pacman::p_load(
  # Utility
  'readxl'
  ,'tictoc'
  # Version control
  ,'usethis'
  ,'gert'
  ,'gitcreds'
  
  # Data manipulation
  ,'data.table'
  ,'tidyverse'
  ,'janitor'
  ,'skimr'
  
  # Statistics, Machine learning and AI
  ,'gemini.R'
  ,'mlr3'
  ,'mlr3learners'
  ,'mlr3cluster'
  ,'mlr3pipelines'
  ,'ranger'
  ,'MASS'
  ,'glmnet'
  ,'iml'
  ,'DHARMa'
  ,'clue'
  
  # Graphing
  ,'plotly'
  
)
## Custom functions ----

## QA ----
cat('Dependencies loaded.\n')
search()

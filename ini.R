# INITIALISATION
# Load, environment variables, packages and custom functions,

## Environment variables ----

## Packages ----
if(!require('pacman')){
  install.packages('pacman')
}

pacman::p_load(
  # Utility
  'usethis'
  ,'gert'
  
  # Data manipulation
  ,'data.table'
  ,'tidyverse'
  ,'janitor'
  ,'skimr'
  
  # Machine learning and AI
  ,'gemini.R'
  ,'mlr3'
  ,'mlr3learners'
  
  # Graphing
  ,'plotly'
  
)
## Custom functions ----

## QA ----
cat('Dependencies loaded.\n')
search()

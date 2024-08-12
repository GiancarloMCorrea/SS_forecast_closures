rm(list = ls())
# Load required libraries:
require(r4ss)
require(dplyr)
require(purrr)
require(tibble)

# Read the forecast settings:
source('config_params.R')

# Run scenarios:
# This might take a while.
source('forecast_closure.R')

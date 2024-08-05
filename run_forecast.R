rm(list = ls())
# Load required libraries:
require(r4ss)
require(dplyr)
require(purrr)
require(tibble)

# Configure the forecast parameters:
source('config_params.R')

# Run scenarios:
source('forecast_closure.R')

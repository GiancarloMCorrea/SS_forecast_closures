require(dplyr)
require(tidyr)
require(tibble)
rm(list = ls())

# Read the forecast settings:
source('config_params.R')

# Read output files:
catch_files = list.files(file.path(out_folder, 'output_catch'), full.names = TRUE)
catch_df = catch_files %>% map(readRDS) %>% bind_rows()
ssb_status_files = list.files(file.path(out_folder, 'output_ssb_status'), full.names = TRUE)
ssb_status_df = ssb_status_files %>% map(readRDS) %>% bind_rows()

# Fill in fleet label:
catch_df$Fleet_name = fleet_codes[catch_df$Fleet]


# -------------------------------------------------------------------------
# Plot reduction in catch -------------------------------------------------

plot_data = catch_df %>% filter(Proj_yr %in% c(0, 1)) %>% select(Fleet_name, Proj_yr, SS_Catch, cfleet:strat)
plot_data = spread(plot_data, Proj_yr, SS_Catch) %>% mutate(Catch_reduction = ((`1`-`0`)/`0`)*100)

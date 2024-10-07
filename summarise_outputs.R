rm(list = ls())

# Read the forecast settings:
source('config_params.R')

# Optional: index label:
label_run = '-LSBBGILL'

# Read output files:
catch_files = list.files(file.path(out_folder, 'output_catch'), full.names = TRUE)
catch_df = catch_files %>% map(readRDS) %>% bind_rows()
ssb_status_files = list.files(file.path(out_folder, 'output_ssb_status'), full.names = TRUE)
ssb_status_df = ssb_status_files %>% map(readRDS) %>% bind_rows()

# Fill in fleet label:
catch_df$Fleet_label = fleet_info$real_fleet_name[catch_df$Fleet]

# Save output data frame:
saveRDS(ssb_status_df, file = file.path(out_folder, paste0(stock_id, '_ssb_status', label_run, '.rds')))
saveRDS(catch_df, file = file.path(out_folder, paste0(stock_id, '_catch', label_run, '.rds')))

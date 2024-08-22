
# -------------------------------------------------------------------------
# Path configuration parameters ------------------------------------------------

# Stock identifier:
stock_id = 'SKJ'

# Path where your SS model is saved. 
grid_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/ICCAT/2022/SKJ'

# SS model folder name (should be located in 'grid_folder'):
model_name = 'noBuoy_50thGrowth_h0.8'

# Path where outputs from this analysis will be saved:
out_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/ICCAT/2022/SKJ_closure'
dir.create(out_folder, showWarnings = FALSE)

# Path where SS executable is located:
ss_folder = 'C:/Use/OneDrive - AZTI/Codes'

# SS executable name in 'ss_folder':
ss_exe = 'ss.exe'


# -------------------------------------------------------------------------
# Read base model:
base_model = SS_output(dir = file.path(grid_folder, model_name), 
                       printstats = FALSE, verbose = FALSE)


# -------------------------------------------------------------------------
# Projection configuration ------------------------------------------------

# Number of projection years:
n_proj_yr = 10

# Projected catch per fishery is calculated from the average of the last 'yr_avg_catch' years of model period:
yr_avg_catch = 3

# Recruitment during projection. Could be 'deterministic' or 'stochastic' 
rec_type = 'deterministic'
# Stochastic option not implemented yet


# -------------------------------------------------------------------------
# Fleet information:

# Inspect the fisheries in SS model:
fleet_info = base_model$definitions %>% dplyr::filter(fleet_type == 1)
fleet_info

# Add a character column to differentiate real fleets. 
# Closures will be applied to these fleets:
fleet_info$real_fleet_name = c('PS', 'PS', 'FS', 'FOB', 'BBPSGhana', 
                               'BB', 'BB', 'BB', 'BB', 'LL')
# Save fleet infomation for reporting:
write.csv(fleet_info, file = file.path(out_folder, paste0(stock_id, '-fleet_information.csv')), row.names = FALSE)

# Fleet active:
# You dont probably want to evaluate closures for all fleets, so here you can
# select the fleets to evaluate:
fleet_info_std = data.frame(real_fleet_name = unique(fleet_info$real_fleet_name))
fleet_info_std$fleet_active = c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE)

# -------------------------------------------------------------------------
# Closures configuration --------------------------------------------------
close_fraction = c(1, 0.66, 0.33) # Closed fraction in a season
# close_fraction = 1: 100% of season is closed, so projected catch is multiplied by (1-1) in that season
# close_fraction = 0.66: 66% of season is closed, so projected catch is multiplied by (1-0.66) in that season
# close_fraction = 0.33: 33% of season is closed, so projected catch is multiplied by (1-0.33) in that season
redist_strat = c(1, 0.5, 0) # Reallocation strategy
# redist_strat = 1: 100% redistribution of 'closed catch' among open seasons in a forecast year
# redist_strat = 0.5: 50% redistribution of 'closed catch' among open seasons in a forecast year
# redist_strat = 0: 0% redistribution of 'closed catch' among open seasons in a forecast year

# Interaction between fleets:
# Instead of redistributing the 'closed catch' of fleet 1 among open seasons in a forecast year, it is assigned to a fleet 2 during the same season
# NULL if no interaction should be tested
interact_fleet = list(c('FOB', 'FS'))

# Annual TAC during projection period
catch_TAC = 220000 # in tons

# Closure scenarios from TAC or status-quo?
do_closure_from_TAC = FALSE

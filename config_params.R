
# -------------------------------------------------------------------------
# Path configuration parameters ------------------------------------------------

# Stock identifier:
stock_id = 'YFT'

# Path where your SS model is saved. 
grid_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2024/YFT-20yr-scale'

# SS model folder name (should be located in 'grid_folder'):
model_name = '6_SplitCPUE_tag01_EC0_h0.8'

# Path where outputs from this analysis will be saved:
out_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2024/YFT_closure'
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

# Add a character column to add fleet labels. These are real fleets. Then save it. 
fleet_info$real_fleet_name = c('GILLLSFSBB','HD','GILLLSFSBB','OT','GILLLSFSBB','GILLLSFSBB','GILLLSFSBB',
                               'GILLLSFSBB','TR','GILLLSFSBB',
                               'GILLLSFSBB','GILLLSFSBB','GILLLSFSBB','OT','TR','GILLLSFSBB',
                               'GILLLSFSBB','TR','GILLLSFSBB','GILLLSFSBB','LF',
                               'GILLLSFSBB','GILLLSFSBB','GILLLSFSBB')
write.csv(fleet_info, file = file.path(out_folder, paste0(stock_id, '-fleet_information.csv')), row.names = FALSE)
# Add fishery group column: Closures will be applied to these groups:
fleet_info$fleet_group = fleet_info$real_fleet_name

# Fleet group active:
# You dont probably want to evaluate closures for all fleets, so here you can
# select the fleet groups to evaluate:
fleet_info_std = data.frame(fleet_group = unique(fleet_info$fleet_group))
fleet_info_std$fleet_active = c(TRUE, FALSE, FALSE, FALSE, FALSE)

# -------------------------------------------------------------------------
# Closures configuration --------------------------------------------------
close_fraction = c(1, 0.66, 0.33) # Closed fraction in a season
# close_fraction = 1: 100% of season is closed, so projected catch is multiplied by (1-1) in that season
# close_fraction = 0.66: 66% of season is closed, so projected catch is multiplied by (1-0.66) in that season
# close_fraction = 0.33: 33% of season is closed, so projected catch is multiplied by (1-0.33) in that season
redist_strat = c(0) # Reallocation strategy
# redist_strat = 1: 100% redistribution of 'closed catch' among open seasons in a forecast year
# redist_strat = 0.5: 50% redistribution of 'closed catch' among open seasons in a forecast year
# redist_strat = 0: 0% redistribution of 'closed catch' among open seasons in a forecast year

# Interaction between fleets:
# Instead of redistributing the 'closed catch' of fleet 1 among open seasons in a forecast year, it is assigned to a fleet 2 during the same season
# NULL if no interaction should be tested
interact_fleet = NULL

# Annual TAC during projection period
catch_TAC = 421000 # in tons

# Closure scenarios from TAC or status-quo?
do_closure_from_TAC = FALSE


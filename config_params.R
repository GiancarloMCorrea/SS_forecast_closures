
# -------------------------------------------------------------------------
# Path configuration parameters ------------------------------------------------

# Stock identifier:
stock_id = 'SKJ'

# Path where your SS model is saved. 
grid_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2021/YFT'
# grid_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2020/SKJ'

# SS model folder name (should be located in 'grid_folder'):
model_name = 'io_h80_q1_Gbase_Mbase_tlambda1'
# model_name = 'io_h80_q0_tlambda1'

# Path where outputs from this analysis will be saved:
out_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2021/YFT_closure'
# out_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2020/SKJ_closure'

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

# Projected catch per fishery is the average of the last 'yr_avg_catch' years of model period:
yr_avg_catch = 5

# Recruitment during projection. Could be 'deterministic' or 'stochastic'
rec_type = 'deterministic'

# Fleet codes:
fleet_codes = c('GI','HD','LL','OT','BB','FS','LL','LS','TR','LL', 'LL','GI','LL','OT','TR','FS','LS','TR','FS','LS','LF')
# fleet_codes = c('LINE', 'LS', 'FS', 'GI', 'HD', 'LL', 'OT')
# This is a vector with length equal to the number of fisheries in the SS model.
# Follow the pattern obtained from:
# base_model = SS_output(dir = model_name)
# base_model$FleetNames[base_model$fleet_type == 1]

# Interaction between fleets:
# NULL if no interaction should be tested
interact_fleet = list(c('LS', 'FS'))

# -------------------------------------------------------------------------
# Closures configuration --------------------------------------------------
close_fraction = c(1, 0.66) # Closed fraction in a season
# close_fraction = 1: 100% of season is closed, so projected catch is multiplied by (1-1) in that season
# close_fraction = 0.66: 66% of season is closed, so projected catch is multiplied by (1-0.66) in that season
# close_fraction = 0.33: 33% of season is closed, so projected catch is multiplied by (1-0.33) in that season
redist_strat = c(0.5, 0) # Reallocation strategy
# redist_strat = 1: 100% redistribution of 'closed catch' among open seasons in a forecast year
# redist_strat = 0.5: 50% redistribution of 'closed catch' among open seasons in a forecast year
# redist_strat = 0: 0% redistribution of 'closed catch' among open seasons in a forecast year

# Annual TAC during projection period
catch_TAC = 400000 # in tons

# Closure scenarios from TAC or status-quo?
do_closure_from_TAC = FALSE

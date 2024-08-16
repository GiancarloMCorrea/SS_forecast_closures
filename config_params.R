
# -------------------------------------------------------------------------
# Path configuration parameters ------------------------------------------------

# Stock identifier:
stock_id = 'YFT'

# Path where your SS model is saved. 
grid_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/ICCAT/2024/YFT'

# SS model folder name (should be located in 'grid_folder'):
model_name = '22_ref_case'

# Path where outputs from this analysis will be saved:
out_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/ICCAT/2024/YFT_closure'
dir.create(out_folder)

# Path where SS executable is located:
ss_folder = 'C:/Use/OneDrive - AZTI/Codes'

# SS executable name in 'ss_folder':
ss_exe = 'ss.exe'

# -------------------------------------------------------------------------
# Projection configuration ------------------------------------------------

# Number of projection years:
n_proj_yr = 10

# Projected catch per fishery is calculated from the average of the last 'yr_avg_catch' years of model period:
yr_avg_catch = 3

# Recruitment during projection. Could be 'deterministic' or 'stochastic' 
rec_type = 'deterministic'
# Stochastic option not implemented yet

# Fleet codes:
fleet_codes = c('FS', 'FS', 'FS', 'FOB', 'BB', 'BB', 'BB',
                'BB', 'BB', 'LL', 'LL', 'LL', 'LL', 'LL', 'LL',
                'HL', 'USRR', 'PSWEST', 'OTH')
# This is a vector with length equal to the number of fisheries in the SS model, and specifies
# the real fisheries in the SS model.
# Follow the pattern obtained from:
# base_model = SS_output(dir = file.path(grid_folder, model_name))
# base_model$FleetNames[base_model$fleet_type == 1]

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
catch_TAC = 110000 # in tons

# Closure scenarios from TAC or status-quo?
do_closure_from_TAC = FALSE

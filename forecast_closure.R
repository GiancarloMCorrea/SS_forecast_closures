source('auxiliary_functions.R')
source('extract_outputs.R')

# Important to create forecast file:
options(max.print=4000)
main_folder = out_folder

# Create folder where SS temporal files will be saved:
dir.create(file.path(out_folder, 'SS_temp'), showWarnings = FALSE)
dir.create(file.path(out_folder, 'output_ssb_status'), showWarnings = FALSE)
dir.create(file.path(out_folder, 'output_catch'), showWarnings = FALSE)
# Folder to run the selected model again, making sure that the forecast is active
# This is important since ss.par is used and it needs to have the right dimensions for forecast rec
dir.create(file.path(out_folder, 'base_with_forecast'), showWarnings = FALSE)


# -------------------------------------------------------------------------
# Define time step in projections:
scale_time = 1/sum(base_model$seasdurations)
last_model_yr = base_model$endyr
first_proj_yr = last_model_yr + 1
last_proj_yr = last_model_yr + n_proj_yr*scale_time
n_seasons = base_model$nseasons
n_times = n_seasons*scale_time

# --------------------------------------------------------------

# Read base files:
base_fore = SS_readforecast(file = file.path(grid_folder, model_name, 'forecast.ss'), verbose = FALSE, readAll = TRUE)
base_fore$benchmarks = 1
base_fore$MSY = 2
base_fore$Forecast = 2 # Fmsy
base_fore$basis_for_fcast_catch_tuning = 2
base_fore$InputBasis = 2
base_fore$Nforecastyrs = n_proj_yr*scale_time

base_starter = SS_readstarter(file = file.path(grid_folder, model_name, 'starter.ss'), verbose = FALSE)
base_starter$init_values_src = 0 # use control file
base_starter$depl_basis = 2 # use Bmsy
base_starter$depl_denom_frac = 1 # B/Bmsy
base_starter$SPR_basis = 2 
base_starter$F_report_units = 4 # avg F ages
base_starter$F_age_range = c(1, max(base_model$endgrowth$int_Age))
base_starter$F_report_basis = 2 # F/Fmsy

# Copy files from selected model folder
r4ss::copy_SS_inputs(dir.old = file.path(grid_folder, model_name), 
                     dir.new = file.path(main_folder, 'base_with_forecast'), verbose = FALSE, 
                     copy_par = FALSE)
# Replace starter and forecast:
SS_writestarter(mylist = base_starter, dir = file.path(main_folder, 'base_with_forecast'), overwrite = TRUE)
SS_writeforecast(mylist = base_fore, dir = file.path(main_folder, 'base_with_forecast'), overwrite = TRUE)

if(!('Report.sso' %in% list.files(path = file.path(main_folder, 'base_with_forecast')))) {
  # Run base model with forecast:
  cat("Running base model with forecast...", "\n")
  r4ss::run(dir = file.path(main_folder, 'base_with_forecast'), extras = '-nohess', exe = file.path(ss_folder, ss_exe), 
            verbose = FALSE, skipfinished = FALSE)
}

# -------------------------------------------------------------------------
# Number of fisheries in SS model (exclude indices)
n_fleets = nrow(fleet_info) 
# Rename column:
fleet_info = fleet_info %>% dplyr::rename(fleet_number = Fleet)

# Select only active fleets
real_fleet_names = fleet_info_std$real_fleet_name[fleet_info_std$fleet_active]
n_real_fleets = length(real_fleet_names)

# -------------------------------------------------------------------------
# Create base forecast catch df:
tmp_df = base_model$catch %>% 
                dplyr::filter(Yr %in% (first_proj_yr - scale_time*yr_avg_catch):(first_proj_yr - 1)) %>% 
                select(Yr, Seas, Fleet, Obs)
tmp_df = tmp_df %>% mutate(Seas = rep(1:n_times, length.out = nrow(tmp_df))) # Real season
tmp_df = tmp_df %>% dplyr::group_by(Seas, Fleet) %>% dplyr::summarise(Catch = mean(Obs), .groups = 'drop')
base_proj = map(seq_len(n_proj_yr), ~tmp_df) %>% bind_rows()
base_proj = base_proj[order(base_proj$Fleet), ]
base_proj = base_proj %>% add_column(Yr = rep(rep(first_proj_yr:last_proj_yr, each = n_seasons), length.out = nrow(base_proj)), .before = 'Seas')
base_proj$Seas = rep(1:n_seasons, length.out = nrow(base_proj)) # Back to SS season
sp_proj = base_proj # this will be the TAC scenario

# Tot catch:
# sp_proj %>% dplyr::filter(Yr < (first_proj_yr + 4)) %>% summarise(totcatch = sum(Catch))

# Calculate annual total catch per fleet during projection period:
catch_proj_df = tmp_df %>% 
  group_by(Fleet) %>% summarise(Catch = sum(Catch), .groups = 'drop')
year_catch_proj = sum(catch_proj_df$Catch)
mult_factor = catch_TAC/year_catch_proj
cat("Mult factor to reach TAC is", round(mult_factor, 2), "\n")

# Reduce proj catch for TAC scenario:
sp_proj$Catch = sp_proj$Catch*mult_factor

# Define data.frame to do projections:
initial_proj = base_proj
if(do_closure_from_TAC) initial_proj = sp_proj

# -------------------------------------------------------------------------
all_proj_yr = first_proj_yr:last_proj_yr # number of projection years
base_factor = base_proj[,c('Yr', 'Seas', 'Fleet')] # will be replaced later
base_factor$Seas_proj = rep(1:n_times, length.out = nrow(base_factor)) # Real season
base_factor$Yr_proj = rep(rep(1:n_proj_yr, each = n_times), length.out = nrow(base_factor)) # Real year
proj_scenario = list() # savel proj catch df
id_list = 1

# Start running scenarios --------------------------------------------------------------
# Copy files to temp folder:
r4ss::copy_SS_inputs(dir.old = file.path(main_folder, 'base_with_forecast'), 
                     dir.new = file.path(main_folder, 'SS_temp'), verbose = FALSE, 
                     copy_par = TRUE, overwrite = TRUE)
# use ss.par in starter and replace in SS_temp:
base_starter$init_values_src = 1 # use par file
SS_writestarter(mylist = base_starter, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)

# Print number of scenarios
n_scenarios = 3 + length(redist_strat)*length(close_fraction)*(n_times + n_times*n_real_fleets + n_times*length(interact_fleet))
cat(n_scenarios, " scenarios will be run:", "\n")

# -------------------------------------------------------------------------
# Status-quo scenario: average catch per fleet is projected
scen_name = 'status-quo_seas_0_fraction_0_strat_0'
# create new forecast catch df:
tmp_proj = base_factor 
tmp_proj = left_join(base_proj, tmp_proj, by=c('Yr', 'Seas', 'Fleet'))
proj_scenario[[id_list]] = tmp_proj[,c('Yr', 'Seas', 'Fleet', 'Catch')]
tmp_fore = base_fore
tmp_fore$ForeCatch = proj_scenario[[id_list]]
# replace forecast file with new one:
r4ss::SS_writeforecast(mylist = tmp_fore, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)
id_list = id_list + 1
# Run SS model:
r4ss::run(dir = file.path(main_folder, 'SS_temp'), extras = '-maxfn 0 -phase 50 -nohess', exe = file.path(ss_folder, ss_exe), 
          verbose = FALSE, skipfinished = FALSE)
# Produce outputs:
extract_outputs(scen_name)
# Remove files in SS_temp:
remove_SS_outfiles()
cat("Scenario ", scen_name, " done", "\n")

# -------------------------------------------------------------------------
# TAC scenario
scen_name = 'TAC_seas_0_fraction_0_strat_0'
# create new forecast catch df:
tmp_proj = base_factor 
tmp_proj = left_join(sp_proj, tmp_proj, by=c('Yr', 'Seas', 'Fleet'))
proj_scenario[[id_list]] = tmp_proj[,c('Yr', 'Seas', 'Fleet', 'Catch')]
tmp_fore = base_fore
tmp_fore$ForeCatch = proj_scenario[[id_list]]
# replace forecast file with new one:
r4ss::SS_writeforecast(mylist = tmp_fore, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)
id_list = id_list + 1
# Run SS model:
r4ss::run(dir = file.path(main_folder, 'SS_temp'), extras = '-maxfn 0 -phase 50 -nohess', exe = file.path(ss_folder, ss_exe), 
          verbose = FALSE, skipfinished = FALSE) 
# Produce outputs:
extract_outputs(scen_name)
# Remove files in SS_temp:
remove_SS_outfiles()
cat("Scenario ", scen_name, " done", "\n")

# -------------------------------------------------------------------------
# Close all fisheries for all seasons
scen_name = 'all_seas_all_fraction_0_strat_0'
# create new forecast catch df:
tmp_proj = base_factor 
tmp_proj = left_join(initial_proj, tmp_proj, by=c('Yr', 'Seas', 'Fleet'))
tmp_proj$Catch = 0
proj_scenario[[id_list]] = tmp_proj[,c('Yr', 'Seas', 'Fleet', 'Catch')]
tmp_fore = base_fore
tmp_fore$ForeCatch = proj_scenario[[id_list]]
# replace forecast file with new one:
r4ss::SS_writeforecast(mylist = tmp_fore, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)
id_list = id_list + 1
# Run SS model:
r4ss::run(dir = file.path(main_folder, 'SS_temp'), extras = '-maxfn 0 -phase 50 -nohess', exe = file.path(ss_folder, ss_exe), 
          verbose = FALSE, skipfinished = FALSE) 
# Produce outputs:
extract_outputs(scen_name)
# Remove files in SS_temp:
remove_SS_outfiles()
cat("Scenario ", scen_name, " done", "\n")

# -------------------------------------------------------------------------
# Closure scenarios

# This uses starter file to make it faster
for(s in seq_along(redist_strat)) {

  for(k in seq_along(close_fraction)) {

    # Close season by season (all fleets): 
    for(i in 1:n_times) {
      
      # Create model directory and copy SS files:
      scen_name = paste0('all_seas_', i,'_fraction_', close_fraction[k], '_strat_', redist_strat[s])
      # create new forecast catch df:
      tmp_proj = base_factor %>% 
        mutate(Factor = ifelse(Seas_proj == i, (1-close_fraction[k]), 1))
      tmp_proj = left_join(initial_proj, tmp_proj, by=c('Yr', 'Seas', 'Fleet'))
      tmp_proj = tmp_proj %>% mutate(YesCatch = Catch*Factor, NoCatch = Catch*(1-Factor))
      out_proj = tmp_proj %>% 
                    group_by(Yr_proj) %>% 
                    group_map(~ dist_catch(.x, factor2 = (1-redist_strat[s]))) %>% 
                    setNames(1:n_proj_yr) %>% 
                    bind_rows()
      proj_scenario[[id_list]] = out_proj %>% select(Yr, Seas, Fleet, FinalCatch)
      tmp_fore = base_fore
      tmp_fore$ForeCatch = proj_scenario[[id_list]]
      # replace forecast file with new one:
      r4ss::SS_writeforecast(mylist = tmp_fore, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)
      id_list = id_list + 1
      # Run SS model:
      r4ss::run(dir = file.path(main_folder, 'SS_temp'), extras = '-maxfn 0 -phase 50 -nohess', exe = file.path(ss_folder, ss_exe), 
                verbose = FALSE, skipfinished = FALSE) 
      # Produce outputs:
      extract_outputs(scen_name)
      # Remove files in SS_temp:
      remove_SS_outfiles()
      cat("Scenario ", scen_name, " done", "\n")
      
    } # season loop
    

    # Close season by season (real_fleet by real_fleet): 
    for(i in 1:n_times) {
      for(j in 1:n_real_fleets) {
        these_fleets = fleet_info %>% dplyr::filter(real_fleet_name == real_fleet_names[j]) %>% select(fleet_number)
        # Create model directory and copy SS files:
        scen_name = paste0(real_fleet_names[j], '_seas_', i,'_fraction_', close_fraction[k], '_strat_', redist_strat[s])
        # create new forecast catch df:
        tmp_proj = base_factor %>% 
          mutate(Factor = ifelse(Seas_proj == i & Fleet %in% these_fleets$fleet_number, (1-close_fraction[k]), 1))
        tmp_proj = left_join(initial_proj, tmp_proj, by=c('Yr', 'Seas', 'Fleet'))
        tmp_proj = tmp_proj %>% mutate(YesCatch = Catch*Factor, NoCatch = Catch*(1-Factor))
        out_proj = tmp_proj %>% 
          group_by(Yr_proj) %>% 
          group_map(~ dist_catch(.x, factor2 = (1-redist_strat[s]))) %>% 
          setNames(1:n_proj_yr) %>% 
          bind_rows()
        proj_scenario[[id_list]] = out_proj %>% select(Yr, Seas, Fleet, FinalCatch)
        tmp_fore = base_fore
        tmp_fore$ForeCatch = proj_scenario[[id_list]]
        # replace forecast file with new one:
        r4ss::SS_writeforecast(mylist = tmp_fore, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)
        id_list = id_list + 1
        # Run SS model:
        r4ss::run(dir = file.path(main_folder, 'SS_temp'), extras = '-maxfn 0 -phase 50 -nohess', exe = file.path(ss_folder, ss_exe), 
                  verbose = FALSE, skipfinished = FALSE) 
        # Produce outputs:
        extract_outputs(scen_name)
        # Remove files in SS_temp:
        remove_SS_outfiles()
        cat("Scenario ", scen_name, " done", "\n")
        
      } # fleet loop
    } # season loop

    # Interaction between fleets:
    if(!is.null(interact_fleet)) {
      for(l in seq_along(interact_fleet)) {
        
        for(i in 1:n_times) {
            fleets_1 = fleet_info %>% dplyr::filter(real_fleet_name == interact_fleet[[l]][1]) %>% select(fleet_number) # 'from' fleet
            fleets_2 = fleet_info %>% dplyr::filter(real_fleet_name == interact_fleet[[l]][2]) %>% select(fleet_number) # 'to' fleet
            # Create model directory and copy SS files:
            scen_name = paste0(interact_fleet[[l]][1], '-', interact_fleet[[l]][2], '_seas_', i,'_fraction_', close_fraction[k], '_strat_', redist_strat[s])
            # create new forecast catch df:
            tmp_proj = base_factor %>% 
              mutate(Factor = ifelse(Seas_proj == i & Fleet %in% fleets_1$fleet_number, (1-close_fraction[k]), 1))
            tmp_proj = left_join(initial_proj, tmp_proj, by=c('Yr', 'Seas', 'Fleet'))
            tmp_proj = tmp_proj %>% mutate(YesCatch = Catch*Factor, NoCatch = Catch*(1-Factor))
            out_proj = tmp_proj %>% 
              group_by(Yr_proj) %>% 
              group_map(~ dist_catch_cross(.x, factor2 = (1-redist_strat[s]), fleet1 = fleets_1$fleet_number, fleet2 = fleets_2$fleet_number)) %>% 
              setNames(1:n_proj_yr) %>% 
              bind_rows()
            proj_scenario[[id_list]] = out_proj %>% select(Yr, Seas, Fleet, FinalCatch)
            tmp_fore = base_fore
            tmp_fore$ForeCatch = proj_scenario[[id_list]]
            # replace forecast file with new one:
            r4ss::SS_writeforecast(mylist = tmp_fore, dir = file.path(main_folder, 'SS_temp'), overwrite = TRUE, verbose = FALSE)
            id_list = id_list + 1
            # Run SS model:
            r4ss::run(dir = file.path(main_folder, 'SS_temp'), extras = '-maxfn 0 -phase 50 -nohess', exe = file.path(ss_folder, ss_exe), 
                      verbose = FALSE, skipfinished = FALSE) 
            # Produce outputs:
            extract_outputs(scen_name)
            # Remove files in SS_temp:
            remove_SS_outfiles()
            cat("Scenario ", scen_name, " done", "\n")
            
        } # season loop
        
      } # list loop
    } #null interact fleets
    
  } # factor loop
  
} # strat loop

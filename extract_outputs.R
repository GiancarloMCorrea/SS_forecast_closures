
extract_outputs = function(scen_name) {
  
  # -------------------------------------------------------------------------
  # Extract outputs and save ------------------------------------------------
  
  tmp_mod = r4ss::SS_output(dir = file.path(main_folder, 'SS_temp'), covar = FALSE, 
                            verbose = FALSE, printstats = FALSE)
  split_model = strsplit(x = scen_name, split = '_')[[1]]
  
  # -------------------------------------------------------------------------
  # Spawning biomass:
  tmp_df1 = tmp_mod$timeseries[, c('Yr', 'Seas', 'SpawnBio')]
  tmp_df1 = tmp_df1 %>% filter(Yr >= (first_proj_yr - scale_time))
  tmp_df1$Seas_proj = 1:(n_seasons*n_times) # Real season
  tmp_df1 = tmp_df1 %>% group_by(Yr, Seas_proj) %>% summarise(SpawnBio = sum(SpawnBio, na.rm = TRUE)) %>% ungroup()
  tmp_df1 = tmp_df1 %>% add_column(Proj_yr = rep(0:n_proj_yr, each = n_times))
  tmp_df1 = tmp_df1 %>% group_by(Proj_yr) %>% summarise(SSB = sum(SpawnBio, na.rm = TRUE))
  
  # -------------------------------------------------------------------------
  # Kobe:
  tmp_df7 = tmp_mod$Kobe %>% filter(Yr >= (first_proj_yr - scale_time))
  tmp_df7 = tmp_df7 %>% add_column(Proj_yr = rep(0:n_proj_yr, each = n_times), .after = 'Yr') %>% select(-Yr)
  tmp_df7 = tmp_df7 %>% group_by(Proj_yr) %>% summarise(BBmsy = mean(B.Bmsy), FFmsy = mean(F.Fmsy))
  
  # Merge SSB and Kobe:
  save_df1 = left_join(tmp_df1, tmp_df7, by = 'Proj_yr')
  save_df1 = save_df1 %>% mutate(cfleet = split_model[1],
                                 cseason = split_model[3],
                                 fraction = split_model[5],
                                 strat = split_model[7]) 
  save_df1 = save_df1 %>% mutate(species = stock_id, .before = 'Proj_yr')
  
  # -------------------------------------------------------------------------
  # Catch (calculated in SS):
  tmp_df2 = tmp_mod$timeseries[, c(2, 1, 4, grep(pattern = 'dead\\(B\\):_', x = colnames(tmp_mod$timeseries)))]
  tmp_df2 = tmp_df2 %>% filter(Yr >= (first_proj_yr - scale_time))
  tmp_df2 = tmp_df2 %>% add_column(Seas_proj = rep(1:(n_seasons*n_times), length.out = nrow(tmp_df2)), .before = 'Seas') # Real season
  tmp_df2 = tmp_df2 %>% group_by(Yr, Seas_proj) %>% summarise_all(list(sum)) %>% select(-c('Area', 'Seas')) %>% ungroup()
  tmp_df2 = tmp_df2 %>% add_column(Proj_yr = rep(0:n_proj_yr, each = n_times), .after = 'Yr')
  tmp_df2 = tmp_df2 %>% dplyr::select(-c('Yr', 'Seas_proj'))
  tmp_df2 = tmp_df2 %>% group_by(Proj_yr) %>% summarise(across(everything(), list(sum)))
  colnames(tmp_df2)[2:ncol(tmp_df2)] = 1:n_fleets
  tmp_df2 = tidyr::gather(tmp_df2, 'Fleet', 'SS_Catch', 2:(n_fleets+1))
  tmp_df2$Fleet = as.numeric(tmp_df2$Fleet)
  # Catch (Input Catch):
  tmp_df3 = as_tibble(tmp_fore$ForeCatch)
  colnames(tmp_df3) = c('Yr', 'Seas', 'Fleet', 'Input_Catch')
  tmp_df3 = tmp_df3[order(tmp_df3$Fleet, tmp_df3$Yr),]
  tmp_df3 = tmp_df3 %>% add_column(Proj_yr = rep(rep(x = 1:n_proj_yr, each = n_times), times = n_fleets),
                                   Seas_proj = rep(x = 1:n_times, length.out = nrow(base_factor)))
  tmp_df3 = tmp_df3 %>% group_by(Proj_yr, Fleet) %>% summarise(Input_Catch = sum(Input_Catch))
  # Merge both df:
  tmp_df4 = left_join(tmp_df2, tmp_df3, by = c('Proj_yr', 'Fleet'))
  
  # Add information:
  save_df2 = tmp_df4 %>% mutate(cfleet = split_model[1],
                                 cseason = split_model[3],
                                 fraction = split_model[5],
                                 strat = split_model[7]) 
  save_df2 = save_df2 %>% mutate(species = stock_id, .before = 'Proj_yr')
  
  # -------------------------------------------------------------------------
  # -------------------------------------------------------------------------
  # Save in folder:
  saveRDS(save_df1, file = file.path(out_folder, 'output_ssb_status', paste0(scen_name, '.rds')))
  saveRDS(save_df2, file = file.path(out_folder, 'output_catch', paste0(scen_name, '.rds')))

}

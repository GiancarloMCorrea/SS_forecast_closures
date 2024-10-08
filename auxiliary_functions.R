# -------------------------------------------------------------------------

dist_catch = function (data, factor2) {
  outData = data %>% group_by(Fleet) %>% 
    mutate(SumFactor = Factor/sum(Factor)) 
  outData = outData %>% group_by(Fleet) %>% mutate(FinalCatch = YesCatch + (1-factor2)*SumFactor*sum(NoCatch))
  return(outData)
}

dist_catch_cross = function (data, factor2, fleet1, fleet2) {
  if(length(fleet1) != length(fleet2)) stop("'fleet1' and 'fleet2' should have the same length")
  outData = data %>% mutate(FinalCatch = YesCatch)
  for(m in seq_along(fleet1)) {
    f1_pos = outData$Fleet %in% fleet1[m]
    f2_pos = outData$Fleet %in% fleet2[m]
    outData[f2_pos, 'FinalCatch'] = outData[f2_pos, 'YesCatch'] + outData[f1_pos, 'NoCatch']*(1-factor2)
  }
  return(outData)
}

remove_SS_outfiles = function(dir = file.path(main_folder, 'SS_temp')) {
  
  out_files = list.files(path = dir)
  pos_to_remove = grep(pattern = '.sso', x = out_files)
  file.remove(file.path(dir, out_files[pos_to_remove]))
  
}

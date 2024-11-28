require(dplyr)
require(tidyr)
require(tibble)
require(ggplot2)
require(quarto)
require(r4ss)
rm(list = ls())

# Read the forecast settings:
# source('config_params.R')
out_folder = 'C:/Use/OneDrive - AZTI/Assessment_models/IOTC/2024/YFT_closure'
fore_file = SS_readforecast(file = file.path(out_folder, 'base_with_forecast/forecast.ss'))
stock_id = 'YFT'
n_proj_yr = 10

# Read summarised outputs:
catch_df = readRDS(file.path(out_folder, paste0(stock_id, '_catch.rds')))
ssb_status_df = readRDS(file.path(out_folder, paste0(stock_id, '_ssb_status.rds')))


# -------------------------------------------------------------------------
# Plot to compare BBmsy and FFmsy among scenarios
first_scen = 25 # plot these scenarios, from highest to lowest 

# Apply scaling factor if needed, to account for recent conditions:
scaling_factor = fore_file$fcast_rec_val # from YFT 2024 assessment
ssb_status_df = ssb_status_df %>% mutate(BBmsy = BBmsy/scaling_factor)

plot_data = ssb_status_df %>% dplyr::filter(Proj_yr == n_proj_yr) %>% 
  select(cfleet, cseason, fraction, strat, BBmsy, FFmsy)

# Some filters:
plot_data = plot_data %>% dplyr::filter(!(cseason == 'all')) # remove unrealistic scenario
alter_scen = plot_data %>% dplyr::filter(cseason == '0') # separate TAC and status-quo
plot_data = plot_data %>% dplyr::filter(!(cseason == '0')) # remove TAC and status-quo

# Labels for closed season
plot_data = plot_data %>% mutate(cseason = paste0('Season closed: ', cseason))
# Replace number of months closed based on 'fraction' column:
plot_data$fraction[plot_data$fraction == '1'] = '3m'
plot_data$fraction[plot_data$fraction == '0.66'] = '2m'
plot_data$fraction[plot_data$fraction == '0.33'] = '1m'
# Replace redistribution of closed catch based on 'strat' column
plot_data$strat = as.character(plot_data$strat)
plot_data$strat[plot_data$strat == '1'] = '100%'
plot_data$strat[plot_data$strat == '0.5'] = '50%'
plot_data$strat[plot_data$strat == '0'] = '0%'
# Change fleet names:
plot_data$cfleet[plot_data$cfleet == 'all'] = 'All'

# Status column:
plot_data = plot_data %>% mutate(status = if_else(BBmsy >= 1 & FFmsy <= 1, '1',
                                                  if_else(BBmsy < 1 & FFmsy <= 1, '2',
                                                          if_else(BBmsy < 1 & FFmsy > 1, '3', '4'))))
# Define colors:
col_status = c('1' = 'green', '2' = 'yellow', '3' = 'red', '4' = 'orange')
# X label columns:
plot_data = plot_data %>% mutate(x_label = paste(cfleet, fraction, sep = '-'))

# Make figure: closures by fleet individually
# plotdat1 = plot_data %>% dplyr::filter(!(cfleet %in% 'LLLSFSBB'))
plotdat1 = plot_data
# Filter scenarios:
summ_data = plotdat1 %>% group_by(x_label) %>% summarise(avg_ind = mean(BBmsy))
summ_data = summ_data[order(summ_data$avg_ind, decreasing = TRUE), ]
n_scen = min(nrow(summ_data), first_scen)
these_scen = summ_data$x_label[1:n_scen]
plotdat1 = plotdat1 %>% dplyr::filter(x_label %in% these_scen)
plotdat1$x_label = factor(plotdat1$x_label, levels = these_scen)
# Add factors (cseason) to alter_scen data frame for plotting:
alter_scentmp = alter_scen %>% slice(rep(1:n(), each = 4))
alter_scentmp = alter_scentmp %>% mutate(cseason = rep(unique(plotdat1$cseason), 2))
alter_scentmp$cfleet[alter_scentmp$cfleet == 'status-quo'] = 'Status quo'
# Plot BBmsy ----------
p1 = ggplot(plotdat1, aes(x = x_label, y = BBmsy, color = as.factor(status)))+
  geom_point(size=3)+
  geom_point(size=3)+
  scale_color_manual(values = col_status) +
  theme_bw()+
  facet_wrap(cseason ~ ., ncol = 2) +
  geom_hline(data = alter_scentmp, aes(yintercept = BBmsy, lty = cfleet)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 8), 
        legend.position = "top") +
  guides(color = 'none', lty = guide_legend(title="Scenario:")) +
  ylim(0, 2.4) + ylab(expression("B/"*B[msy]*" in last projection year")) + xlab(NULL) 
ggsave(file.path(out_folder, paste0(stock_id, '_BBmsy_1.png')), plot = p1,
       width = 170, height = 140, units = 'mm', dpi = 500)
# 
# # Make figure: closures by fleet group
# plotdat1 = plot_data %>% dplyr::filter(cfleet %in% c('All', 'LLLSFSBB'))
# # Filter scenarios:
# summ_data = plotdat1 %>% group_by(x_label) %>% summarise(avg_ind = mean(BBmsy))
# summ_data = summ_data[order(summ_data$avg_ind, decreasing = TRUE), ]
# n_scen = min(nrow(summ_data), first_scen)
# these_scen = summ_data$x_label[1:n_scen]
# plotdat1 = plotdat1 %>% dplyr::filter(x_label %in% these_scen)
# plotdat1$x_label = factor(plotdat1$x_label, levels = these_scen)
# # Add factors (cseason) to alter_scen data frame for plotting:
# alter_scentmp = alter_scen %>% slice(rep(1:n(), each = 4))
# alter_scentmp = alter_scentmp %>% mutate(cseason = rep(unique(plotdat1$cseason), 2))
# alter_scentmp$cfleet[alter_scentmp$cfleet == 'status-quo'] = 'Status quo'
# # Plot BBmsy ----------
# p2 = ggplot(plotdat1, aes(x = x_label, y = BBmsy, color = as.factor(status)))+
#   geom_point(size=3)+
#   geom_point(size=3)+
#   scale_color_manual(values = col_status) +
#   theme_bw()+
#   facet_wrap(cseason ~ ., ncol = 2) +
#   geom_hline(data = alter_scentmp, aes(yintercept = BBmsy, lty = cfleet)) +
#   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 8), 
#         legend.position = "top") +
#   guides(color = 'none', lty = guide_legend(title="Scenario:")) +
#   ylim(0, 2.4) + ylab(expression("B/"*B[msy]*" in last projection year")) + xlab(NULL) 
# ggsave(file.path(out_folder, paste0(stock_id, '_BBmsy_2.png')), plot = p2,
#        width = 170, height = 140, units = 'mm', dpi = 500)

require(dplyr)
require(tidyr)
require(tibble)
require(ggplot2)
require(quarto)
require(r4ss)
rm(list = ls())

# Read the forecast settings:
source('config_params.R')

# Read summarised outputs:
catch_df = readRDS(file.path(out_folder, paste0(stock_id, '_catch.rds')))
ssb_status_df = readRDS(file.path(out_folder, paste0(stock_id, '_ssb_status.rds')))

# -------------------------------------------------------------------------
# Plot status-quo catch -------------------------------------------------

plot_data = left_join(catch_df, fleet_info[,c('Fleet', 'Fleet_name')], by = 'Fleet')
plot_data = plot_data %>% dplyr::filter(Proj_yr %in% 0, cfleet == 'all', cseason == '1', fraction == '1', strat == '0.5') %>% 
  select(Fleet_name, Proj_yr, SS_Catch, cfleet:strat)
plot_data$Fleet_name = factor(plot_data$Fleet_name, levels = fleet_info$Fleet_name)

g1 = ggplot(data = plot_data, aes(x = Fleet_name, y = SS_Catch*1e-03)) +
  geom_col() +
  ylab('Status-quo catch (thousands of tons)') + xlab(NULL) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 8))
ggsave(file.path(out_folder, paste0(stock_id, '_stquo-catch.png')), plot = g1,
       width = 170, height = 140, units = 'mm', dpi = 500)

# -------------------------------------------------------------------------
# Plot to compare BBmsy and FFmsy among scenarios
first_scen = 25 # plot these scenarios, from highest to lowest 

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
plot_data = plot_data %>% mutate(x_label = paste(cfleet, fraction, strat, sep = '-'))
# Filter scenarios:
summ_data = plot_data %>% group_by(x_label) %>% summarise(avg_ind = mean(BBmsy))
summ_data = summ_data[order(summ_data$avg_ind, decreasing = TRUE), ]
these_scen = summ_data$x_label[1:first_scen]
plot_data = plot_data %>% dplyr::filter(x_label %in% these_scen)

# Add factors (cseason) to alter_scen data frame for plotting:
alter_scen = alter_scen %>% slice(rep(1:n(), each = 4))
alter_scen = alter_scen %>% mutate(cseason = rep(unique(plot_data$cseason), 2))
alter_scen$cfleet[alter_scen$cfleet == 'status-quo'] = 'Status quo'

# Order based on BBmsy:
plot_data = plot_data[order(plot_data$BBmsy, decreasing = TRUE), ]

# Plot BBmsy ----------
p1 = ggplot(plot_data, aes(x = x_label, y = BBmsy, color = as.factor(status)))+
  geom_point(size=3)+
  geom_point(size=3)+
  scale_color_manual(values = col_status) +
  theme_bw()+
  facet_wrap(cseason ~ ., ncol = 2) +
  geom_hline(data = alter_scen, aes(yintercept = BBmsy, lty = cfleet)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 8), 
        legend.position = "top") +
  guides(color = 'none', lty = guide_legend(title="Scenario:")) +
  ylim(0, 2.4) + ylab(expression("B/"*B[msy]*" in last projection year")) + xlab(NULL) 
ggsave(file.path(out_folder, paste0(stock_id, '_BBmsy.png')), plot = p1,
       width = 170, height = 140, units = 'mm', dpi = 500)

# Plot FFmsy ----------
p2 = ggplot(plot_data, aes(x = x_label, y = FFmsy, color = as.factor(status)))+
  geom_point(size=3)+
  geom_point(size=3)+
  scale_color_manual(values = col_status) +
  theme_bw()+
  facet_wrap(cseason ~ ., ncol = 2) +
  geom_hline(data = alter_scen, aes(yintercept = FFmsy, lty = cfleet)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 8), 
        legend.position = "top") +
  guides(color = 'none', lty = guide_legend(title="Scenario:")) +
  ylim(0,2)+ylab(expression("F/"*F[msy]*" in last projection year")) + xlab(NULL) 
ggsave(file.path(out_folder, paste0(stock_id, '_FFmsy.png')), plot = p2,
       width = 170, height = 140, units = 'mm', dpi = 500)


# Impacts of temporal closure scenarios on stock status

Evaluate the impacts of seasonal fisheries closures on the stock status during a projection period using [Stock Synthesis](https://vlab.noaa.gov/web/stock-synthesis) (SS). 

You need to have a stock assessment model implemented in SS. The SS model could have multiple seasons, or use the semesters-as-years or quarters-as-years approach.

## Closure scenarios

We evaluate the impacts of fleet-by-fleet and all-fleets-at-once seasonal closures on spawning biomass (SSB), stock status ($B/B_{msy}$ and $F/F_{msy}$), and catch during a **projection period**.

In addition to the evaluated closure scenarios, we also assess these projection scenarios:

- *status-quo*: assumes an average catch per fleet and season from the last years of the assessment period. No closures applied.
- *TAC*: assumes a total annual catch equal to a Total Allowable Catch (TAC). Projected catch per fleet and season is calculated from the *status-quo* scenario, and then increased or decreased proportionally to reach the TAC. No closures applied.
- *all-closed*: assumes zero catch for all fleets and seasons. This is an unrealistic scenario but useful for comparison.

## Things to consider

- Your SS forecast and starter file should be named `forecast.ss` and `starter.ss`, respectively.
- Be aware of the projection configuration in your forecast file.
- The current code works with MSY-based reference points, but could be easily adapted to any type of reference point. Contact me if you have questions.

## Steps to run this analysis

1. Open `config_params.R` and specify the configuration parameters. Follow the inscructions in that script.
2. Run `run_forecast.R`. You will see that three folders are created (`output_catch`, `output_ssb_status`, `SS_temp`), and several RDS files are stored in them. This step might take a while.
3. Make plots to summarise using `make_figures.R`. Modify the code as desired.
4. Produce an summary table in Word by running `make_table.qmd`. Modify the code as needed based on the closure scenarios.

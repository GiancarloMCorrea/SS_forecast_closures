# Impacts of temporal closure scenarios on stock status

Evaluate the impacts of seasonal fisheries closure scenarios on stock status during a projection period using [Stock Synthesis](https://vlab.noaa.gov/web/stock-synthesis) (SS). 

You need to have a stock assessment model implemented in SS. The SS model could have multiple seasons, or use the semesters-as-years or quarters-as-years approach.

## Closure scenarios

We evaluate the impacts of fleet-by-fleet and all-fleets-at-once seasonal closures on spawning biomass (SSB), stock status ($B/B_{msy}$ and $F/F_{msy}$), and catch during a projection period.

In addition to the evaluated closure scenarios, we also assess these projection scenarios:

- *status-quo*: assumes an average catch per fleet and season from the last years.
- *TAC*: assumes a total annual catch equal to a Total Allowable Catch (TAC). Projected catch per fleet and season is calculated from the *status-quo* scenario, and then increased or decreased proportionally to reach the TAC.
- *all-closed*: assumes zero catch for all fleets and seasons.

## Things to consider

- Your SS forecast and starter file should be named `forecast.ss` and `starter.ss`, respectively.
- Double check your forecast file to make sure you are using the desired projection configuration.
- The current code works with MSY-based reference points, but could be easily adapted to any type of reference point. Contact me if you have questions.

## Steps to run this analysis

1. Open `config_params.R` and specify the configuration parameters. Follow the inscructions in that script.
2. Run `run_forecast.R`. You will see that several files are created in your working directory, depending on how many scenarios you ran.

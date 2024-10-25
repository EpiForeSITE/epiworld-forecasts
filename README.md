# Epiworld Forecasts

This project is currently under construction and will have the following functionality:
- Gets health data from public source (e.g., DHHS) for Salt Lake county or all of Utah
- Calibrates a model using the data
- Does a forecast using the calibrated model and the [`epiworld`](https://github.com/UofUEpiBio/epiworld/) simulation tool
- Generates a report with figures and descriptions
- Publishes the report via GitHub Pages

The forecast will update automatically each week using GitHub Actions.

## Data Sources
We are currently planning to use the [weekly reports](https://coronavirus.utah.gov/case-counts/) published by Utah DHHS on COVID-19.

Other possible data sources include:
- Utah DHHS publishes [weekly reports](https://coronavirus.utah.gov/case-counts/) on COVID-19, Influenza, and Respiratory syncytial virus (RSV).
- Germ Watch could be another great public source, but is currently unavailable (links, such as those mentioned [here](https://epi.utah.gov/influenza-reports/) redirect to Intermountain's home page)
- DELPHI maintains a frequently updated COVID data API [here](https://cmu-delphi.github.io/delphi-epidata/api/covidcast.html) and additional endpoints (less frequently updated) for influenza, dengue, and norovirus [here](https://cmu-delphi.github.io/delphi-epidata/api/README.html)
- CDC's [public datasets](https://data.cdc.gov), some are updated infrequently, others are weekly estimates (e.g., [weekly flu vaccine estimates](https://data.cdc.gov/Vaccinations/Weekly-Cumulative-Estimated-Number-of-Influenza-Va/ysd3-txwj/about_data)
- Germ watch

### Other Relevant Resources
It's worth also taking a look at:
- DELPHI's [R packages](https://delphi.cmu.edu/code/)
- [RSV Forecast Hub](https://rsvforecasthub.org/#Overview)
- [Epinowcast](https://www.epinowcast.org) and the Epinowcast [community forums](https://community.epinowcast.org)

## Code of Conduct

Please note that the epiworld-forecasts project is released with a [Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html). By contributing to this project, you agree to abide by its terms. More information about how to contribute to the project can be found under [`DEVELOPMENT.md`](DEVELOPMENT.md).

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

## Building Container Image
Use the Dockerfile in [`.devcontainer/`] to build the `epiworld-forecasts` image.
The image includes [`rocker/tidyverse`](https://rocker-project.org/images/versioned/rstudio.html) and [`epiworldR`](https://github.com/UofUEpiBio/epiworldR).
It is stored on the Github Container Registry (`ghcr.io/`).

**Note for macOS users (M-series chip):** Pulling and building the `rocker/tidyverse` image may require specifying the platform with `--platform=linux/amd64`

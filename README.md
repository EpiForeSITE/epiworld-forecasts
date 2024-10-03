# Epiworld Forecasts

This project is currently under construction and will have the following functionality:
- Gets health data from public source (e.g., DHHS) for Salt Lake county or all of Utah
- Calibrates a model using the data
- Does a forecast using the calibrated model and the [`epiworld`](https://github.com/UofUEpiBio/epiworld/) simulation tool
- Generates a report with figures and descriptions
- Publishes the report via GitHub Pages

The forecast will update automatically each week using GitHub Actions.

## Data Sources
We are currently planning to use the [weekly reports](https://coronavirus.utah.gov/case-counts/) published by Utah DHHS on COVID-19, Influenza, and Respiratory syncytial virus (RSV).

In the future, we may use Germ Watch or additional public data sources.

## Building Container Image
Use the Dockerfile in [`.devcontainer/`] to build the `epiworld-forecasts` image. 
The image includes [`rocker/tidyverse`](https://rocker-project.org/images/versioned/rstudio.html) and [`epiworldR`](https://github.com/UofUEpiBio/epiworldR). 
It is stored on the Github Container Registry (`ghcr.io/`).

**Note for macOS users:** Pulling and building the `rocker/tidyverse` image require specifying the platform with `--platform=linux/amd64`
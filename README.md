# epiworld-forecasts

`epiworld-forecasts` is a template repository that provides scaffolding for automated disease forecasts using [`epiworldR`](https://github.com/UofUEpiBio/epiworldR/), an R package for fast agent-based model (ABM) disease simulations.

Disease forecasts typically follow these steps:

1. Gather data
2. Calibrate a model on the data
3. Make a forecast with the calibrated model
4. Create a report with figures and descriptions
5. Publish the report

The epiworld-forecasts tool automates these steps, creating forecasts that regularly update without human intervention. This saves researchers and public health officials time and effort.


## Technologies

**`epiworld-forecasts`** is fully automated, powered by the following technologies:

* **Docker:** Contains all the software packages needed to run the forecast
* **GitHub Actions:** Runs the forecast inside the Docker container, manages the schedule of forecast runs, builds and pushes the Docker image to the GitHub Container Registry
* **Quarto:** Generates the forecast's report in an HTML webpage which is then published to GitHub Pages
* **GitHub:** Hosts source code repository and forecast website via GitHub Pages

![](assets/tech-chart.png)


## Example Forecast

To demonstrate the capabilities of `epiworld-forecasts`, we created an example forecast.
This is a 14-day forecast of COVID-19 case counts in Utah using data published weekly by the UDHHS.
The forecast updates weekly and is published to [this website](https://epiforesite.github.io/epiworld-forecasts/).

![](assets/process-flow-chart.png)


## Adapting `epiworld-forecasts` for Your Needs

The core of this tool is the pipeline technologies (GHA Actions, Docker, Quarto) that allow the forecast to run automatically.
As such, the tool can be adapted for different:

* Data sources
* Model calibrations
* Forecast characteristics (algorithm used, duration of forecast, etc.)
* Report characteristics (text, figures, etc.)
* Publishing destinations (website, PDF, etc.)
* Forecast schedules
* Docker containers

You can make adaptations to these features by modifying the following key files:

[**`function.R`**](./functions.R) contains the core logic for the forecast divided up into the following sections:
* *Libraries:* Loads required libraries, such as `epiworldR` and `ggplot2`
* *Gather Data:* Defines functions for getting the data to calibration the forecast
* *Process Data:* Defines functions for processing data for the forecast
* *Model Definition:* Defines the disease model (e.g., SIR connected), including initial disease parameters
* *Model Calibration:* Defines the functions and variables for calibrating the forecast model (e.g., LFMCMC)
* *Run Model Calibration:* Executes the calibration functions defined above
* *Run Forecast:* Runs the forecast with the calibrated model
* *Forecast Visualizations:* Defines functions for visualizing forecast data
All of these sections can be modified freely to produce your intended forecast.

[**`index.qmd`**](./index.qmd) defines the `index.html` page for the final generated forecast report.
This file should always start with `source("functions.R")` to run the forecast and load in all relevant functions, but most subsections will only call printing or plotting functions (as defined in the "Forecast Visualizations" section of `functions.R`).
By dividing the "business" logic from the HTML render logic, we make it easier to run the code outside of the Quarto file and also allow multiple web pages to show different visualizations from the same forecast run.
This file can also be freely customized to your needs.

[**`run-forecast.yml`**](./.github/workflows/run-forecast.yml) contains the GitHub Actions workflow for running the forecast automatically.
This includes setting the schedule and uploading the HTML forecast report to GitHub Pages, which is what you will most likely be modifying for your project.
Take careful consideration before modifying anything other than the schedule and publishing destination to avoid breaking the workflow.

[**`Dockerfile`**](./.devcontainer/Dockerfile) defines the Docker image for running the forecast.
This should contain all the packages you need for your forecast (e.g., `epiworldR`, `ggplot2`, etc.).
We have a separate GHA workflow file for [building the Docker image](./.github/workflows/build-docker-image.yml) from the Dockerfile so it can be used by the GHAs.

Our example features additional [Methodology](./methodology.qmd) and [About](./about.qmd) pages, but these are not required for your project.
Adjust the global website settings in the [`_quarto.yml`](./_quarto.yml) file.


## Data Sources
For our example forecast, we use the [weekly reports](https://coronavirus.utah.gov/case-counts/) published by Utah DHHS on COVID-19.
This includes a lot of different data, but we focus on COVID-19 case counts for the entire state.

Future forecasts, might look to other data sources, such as:
- DELPHI maintains a frequently updated COVID data API [here](https://cmu-delphi.github.io/delphi-epidata/api/covidcast.html) and additional endpoints (less frequently updated) for influenza, dengue, and norovirus [here](https://cmu-delphi.github.io/delphi-epidata/api/README.html)
- CDC's [public datasets](https://data.cdc.gov), some are updated infrequently, others are weekly estimates (e.g., [weekly flu vaccine estimates](https://data.cdc.gov/Vaccinations/Weekly-Cumulative-Estimated-Number-of-Influenza-Va/ysd3-txwj/about_data)


## Other Relevant Resources
It's worth also taking a look at:
- DELPHI's [R packages](https://delphi.cmu.edu/code/)
- [RSV Forecast Hub](https://rsvforecasthub.org/#Overview)
- [Epinowcast](https://www.epinowcast.org) and the Epinowcast [community forums](https://community.epinowcast.org)


## Code of Conduct

The `epiworld-forecasts` project is released with a [Contributor Code of Conduct](./CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
More information about how to contribute to the project can be found under [`DEVELOPMENT.md`](DEVELOPMENT.md).

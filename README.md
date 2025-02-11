# epiworld-forecasts

`epiworld-forecasts` is a template repository that provides scaffolding for building automatic disease forecasts.

## How It Works

Disease forecasts typically follow these steps:

1. Gather data
2. Calibrate a model on the data
3. Make a forecast with the calibrated model
4. Create a report with figures and descriptions
5. Publish the report

`epiworld-forecasts` automates these steps, creating forecasts that regularly update without human intervention.

### Technologies

`epiworld-forecasts` is powered by these technologies:

1. [**`epiworldR`**](https://github.com/UofUEpiBio/epiworldR/): R package for fast agent-based model (ABM) disease simulations
2. **Docker:** Contains all the software packages needed to run the forecast
3. **GitHub Actions:** Runs the forecast inside the Docker container, manages the schedule of forecast runs, builds and pushes the Docker image to the GitHub Container Registry
4. **Quarto:** Generates the forecast's report in an HTML webpage which is then published to GitHub Pages
5. **GitHub:** Hosts source code repository and forecast website via GitHub Pages

### Adapting to Your Needs

The `epiworld-forecasts` pipeline which can be adapted for different:

* Data sources
* Model calibrations
* Forecast characteristics (algorithm used, duration of forecast, etc.)
* Report characteristics (text, figures, etc.)
* Publishing destinations (website, PDF, etc.)
* Forecast schedules
* Docker containers

You adjust the tool for your projects by first [creating a new repo from this template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) and then modifying the following key files:

[**`forecast.R`**](./forecast.R) contains the core logic for the forecast divided up into the following sections:

* *Libraries:* Loads required libraries, such as `epiworldR` and `ggplot2`
* *Gather Data:* Defines functions for getting the data to calibration the forecast
* *Process Data:* Defines functions for processing data for the forecast
* *Model Definition:* Defines the disease model (e.g., SIR connected), including initial disease parameters
* *Model Calibration:* Defines the functions and variables for calibrating the forecast model (e.g., LFMCMC)
* *Run Model Calibration:* Executes the calibration functions defined above
* *Run Forecast:* Runs the forecast with the calibrated model
* *Forecast Visualizations:* Defines functions for visualizing forecast data

[**`index.qmd`**](./index.qmd) defines the `index.html` page for the final generated forecast report.

* This file should always start with `source("forecast.R")` to run the forecast and source all relevant functions, but subsections will only call printing or plotting functions (e.g., those defined under "Forecast Visualizations" in `forecast.R`).
* By dividing the "business" logic from the HTML rendering logic, we make it easier to run the code outside of the Quarto file (i.e. without rendering the entire webpage).
This also allows multiple web pages to show different visualizations from the same forecast run.
* Our example (below) features additional [Methodology](./methodology.qmd) and [About](./about.qmd) pages, but these are not required for your project.
Adjust the global website settings in the [`_quarto.yml`](./_quarto.yml) file.

[**`run-forecast.yml`**](./.github/workflows/run-forecast.yml) contains the GitHub Actions workflow for running the forecast automatically.

* This includes setting the schedule and publishing the report.
* While our example (below) uploads the HTML forecast to GitHub Pages, this workflow can be adapted to simply produce a downloadable data file, rather than publishing a public website.
* Be careful when modifying anything other than the container, the schedule, and publishing destination to avoid breaking the workflow.

[**`Dockerfile`**](./.devcontainer/Dockerfile) defines the Docker image for running the forecast.

* This should contain all the packages you need for your forecast (e.g., `epiworldR`, `ggplot2`, etc.).
* We have a separate GHA workflow file for [building the Docker image](./.github/workflows/build-docker-image.yml) from the Dockerfile so it can be used by the GHAs.

#### Implementation Note

Once you copy the template repository, the `build-docker-image` workflow will create the Docker image for your new repository.
Consequently, you'll need to modify the [container in `run-forecast.yml`](https://github.com/EpiForeSITE/epiworld-forecasts/blob/0ef3472bd5084bb3a95a646e07d218cd2154725a/.github/workflows/run-forecast.yml#L36) to the newly built docker image:
```
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest
    container: ghcr.io/epiforesite/epiworld-forecasts -> change to "ghcr.io/<your_org_name>/<your_repo_name>"
    permissions:
      contents: write
```
Otherwise, your project will continue to use our `epiworld-forecasts` Docker image.


## Example Forecast

To demonstrate the capabilities of `epiworld-forecasts`, we created an example forecast.
This is a 14-day forecast of COVID-19 case counts in Utah using data [published weekly](https://coronavirus.utah.gov/case-counts/) by Utah DHHS
The forecast updates weekly and is published to [this website](https://epiforesite.github.io/epiworld-forecasts/).

![](assets/process-flow-chart.png)


## Code of Conduct

The `epiworld-forecasts` project is released with a [Contributor Code of Conduct](./CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.
More information about how to contribute to the project can be found under [`DEVELOPMENT.md`](DEVELOPMENT.md).

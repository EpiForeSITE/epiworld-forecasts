## ----------------------------------
## GENERAL FUNCTIONS
## ----------------------------------
source("forecast-pkg.R")
source("plot-forecast.R")
library(tidyr)

## ----------------------------------
## HELPER FUNCTIONS
## ----------------------------------

get_covid_data <- function(n_days) {
  # Download the Trends data from Utah DHSS
  # - URL for UDHHS COVID-19 data (returns a zip archive with multiple files)
  data_url <- "https://coronavirus-dashboard.utah.gov/Utah_COVID19_data.zip"
  # - Target file from the above zip archive
  target_file_regex <- "Trends_Epidemic+"
  # - Perform data extraction
  forecast_data <- get_data_from_url(data_url, target_file_regex)
  # - Format date column properly
  forecast_data$Date <- as.Date(forecast_data$Date)

  # Extract last n_days of data
  last_date <- max(forecast_data$Date)
  forecast_data <- forecast_data[forecast_data$Date > (last_date - n_days), ]
  return(forecast_data) # TODO: remove return statements
}

## ----------------------------------
## LFMCMC FUNCTIONS
## ----------------------------------

# Define the LFMCMC summary function
lfmcmc_summary_fun <- function(case_counts) {
  # Extract summary statistics from the data
  time_to_peak <- which.max(case_counts)
  size_of_peak <- case_counts[time_to_peak]
  mean_cases <- mean(case_counts)
  sd_cases <- sd(case_counts)

  c(
    time_to_peak,
    size_of_peak,
    mean_cases,
    sd_cases
  )
}

# Define the LFMCMC summary function
lfmcmc_proposal_fun <- function(params_prev) {
  # Propose new model parameters
  params_1_to_5 <- plogis(
    qlogis(params_prev[1:5]) +
      rnorm(length(params_prev[1:5]), mean = 0, sd = 0.025)
  )

  params_6_to_7 <- params_prev[6:7] +
    rnorm(2, mean = 0, sd = 0.025)


  # Reflect contact rates
  if (params_6_to_7[1] < 0) {
    params_6_to_7[1] <- params_prev[6] -
      (params_6_to_7[1] - params_prev[6])
  }
  if (params_6_to_7[2] < 0) {
    params_6_to_7[2] <- params_prev[7] -
      (params_6_to_7[2] - params_prev[7])
  }

  # Return proposed parameters
  c(params_1_to_5, params_6_to_7)
}

# Define the LFMCMC kernel function
# - Weighs simulation results against observed data
lfmcmc_kernel_fun <- function(simulated_stats, observed_stats, epsilon) {
  diff <- ((simulated_stats - observed_stats)^2)^epsilon
  dnorm(sqrt(sum(diff)))
}

# Function to return accepted parameters from LFMCMC
# TODO: Refactor to reduce function inputs
get_params_sample <- function(lfmcmc_obj, total_samples, burnin, sample_size) {
  accepted_params <- get_accepted_params(lfmcmc_obj)
  burnin_sample <- tail(accepted_params, n = (total_samples - burnin))
  params_sample <- burnin_sample[sample(nrow(burnin_sample), sample_size), ]
  return(params_sample)
}

## ----------------------------------
## RUN FORECAST
## ----------------------------------

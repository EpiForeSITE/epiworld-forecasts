## ----------------------------------
## GENERAL FUNCTIONS
## ----------------------------------
source("forecast-pkg.R")
source("plot-forecast.R")
library(tidyr)

## ----------------------------------
## HELPER FUNCTIONS
## ----------------------------------

#' Get COVID-19 case counts from UDHHS
#'
#' @description
#' `get_covid_data` downloads the COVID-19 dataset from UDHHS.
#'
#' @details
#' This function downloads the COVID-19 daily case count dataset
#' from UDHHS, returning the data from the last N days.
#'
#' @param n_days Integer value.
#'
#' @returns The COVID-19 case count data.
get_covid_data <- function(n_days) {
  # Download the Trends data from Utah DHSS
  # - URL for UDHHS COVID-19 data (returns a zip archive with multiple files)
  data_url <- "https://coronavirus-dashboard.utah.gov/Utah_COVID19_data.zip"
  # - Target file from the above zip archive
  target_file_regex <- "Trends_Epidemic+"
  # - Perform data extraction
  covid_data <- get_data_from_url(data_url, target_file_regex)
  # - Format date column properly
  covid_data$Date <- as.Date(covid_data$Date)

  # Extract last n_days of data
  last_date <- max(covid_data$Date)
  covid_data <- covid_data[covid_data$Date > (last_date - n_days), ]
  return(covid_data)
}

## ----------------------------------
## LFMCMC FUNCTIONS
## ----------------------------------

#' Define the LFMCMC summary function
#'
#' @description
#' `lfmcmc_summary_fun` defines the summary function for LFMCMC.
#'
#' @details
#' In LFMCMC, the summary function computes summary statistics which
#' are used to compare the simulation function output with the observed
#' data. It must perform the same with the observed dataset
#' as it does with the results of the LFMCMC simulation function.
#' This function takes a vector of case counts and computes
#' `time_to_peak` (how many days to the highest case count),
#' `size_of_peak`, as well as the mean and standard deviation.
#'
#' @param case_counts Vector of integer case counts.
#' @param lfmcmc_obj Object of class [LFMCMC].
#'
#' @returns A vector of summary statistics.
lfmcmc_summary_fun <- function(case_counts, lfmcmc_obj) {

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

#' Define the LFMCMC proposal function
#'
#' @description
#' `lfmcmc_proposal_fun` defines the proposal function for LFMCMC.
#'
#' @details
#' In LFMCMC, the proposal function generates new model parameters
#' to be used in the next run of the simulation function.
#' This function takes a vector of parameters (the set used in
#' the previous run) and takes a random step from those values
#' to compute new ("proposed") values.
#'
#' @param params_prev Vector of numeric parameter values.
#' @param lfmcmc_obj Object of class [LFMCMC].
#'
#' @returns A vector of proposed parameter values.
lfmcmc_proposal_fun <- function(params_prev, lfmcmc_obj) {
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

#' Define the LFMCMC kernel function
#'
#' @description
#' `lfmcmc_kernel_fun` defines the kernel function for LFMCMC.
#'
#' @details
#' In LFMCMC, the kernel function weighs the summary statistics from
#' the latest run of the simulation function against the summary
#' statistics of the observed data.
#'
#' @param simulated_stats Vector of numeric summary stats for simulated data.
#' @param observed_stats Vector of numeric summary stats for observed data.
#' @param epsilon Numeric epsilon value.
#' @param lfmcmc_obj Object of class [LFMCMC].
#'
#' @returns A numeric kernel score.
lfmcmc_kernel_fun <- function(simulated_stats, observed_stats, epsilon, lfmcmc_obj) {
  diff <- ((simulated_stats - observed_stats)^2)^epsilon
  dnorm(sqrt(sum(diff)))
}

#' Get a sample of accepted parameters from LFMCMC
#'
#' @description
#' `get_params_sample` gets a sample of accepted parameters from the
#' LFMCMC run after the burn-in period.
#'
#' @param lfmcmc_obj Object of class [LFMCMC].
#' @param total_samples Integer total samples from the LFMCMC object.
#' @param burnin Integer burn-in period for the LFMCMC object.
#' @param sample_size Integer number of samples to take.
#'
#' @returns An array of numeric vectors where each
#' vector represents a single sample set of parameters.
get_params_sample <- function(lfmcmc_obj, total_samples, burnin, sample_size) {
  accepted_params <- get_all_accepted_params(lfmcmc_obj)
  burnin_sample <- tail(accepted_params, n = (total_samples - burnin))
  params_sample <- burnin_sample[sample(nrow(burnin_sample), sample_size), ]
  return(params_sample)
}

## ----------------------------------
## Setup Forecast
## ----------------------------------
# Define forecast parameters
n_days <- 90 # Calibrate model last 90 days of data

## ----------------------------------
## Get Data
## ----------------------------------

# Get COVID-19 data
covid_data <- get_covid_data(n_days)
# Compute start date for each season
seasons <- get_season_starts(covid_data$Date)
# Get observed case counts
covid_cases <- covid_data$Daily.Cases

## ----------------------------------
## Create SIR CONN Model
## ----------------------------------

# Define SIRCONN model parameters
model_seed          <- 112      # Random seed
model_ndays         <- n_days   # How many days to run the model
model_n             <- 10000    # model population size

# Define initial disease parameters
init_prevalence <- covid_cases[1] / model_n
init_contact_rate <- 10
init_transmission_rate <- 0.05
init_recovery_rate <- 1 / 7

# Create the SIRCONN model
covid_sirconn_model <- ModelSIRCONN(
  name              = "COVID-19",
  n                 = model_n,
  prevalence        = init_prevalence,
  contact_rate      = init_contact_rate,
  transmission_rate = init_transmission_rate,
  recovery_rate     = init_recovery_rate
)

## ----------------------------------
## Setup LFMCMC Calibration
## ----------------------------------

# Define LFMCMC parameters
lfmcmc_n_samples <- 6000   # number of LFMCMC iterations
lfmcmc_burnin <- 2000    # burn-in period
lfmcmc_epsilon <- 0.25

init_lfmcmc_params <- c(
  1 / 7,  # r_rate
  0.05,   # t_rate_spring
  0.04,   # t_rate_summer
  0.06,   # t_rate_fall
  0.07,   # t_rate_winter
  10,     # c_rate_weekday
  2       # c_rate_weekend
)
param_names <- c(
  "Recovery rate",
  "Transmission rate (spring)",
  "Transmission rate (summer)",
  "Transmission rate (fall)",
  "Transmission rate (winter)",
  "Contact rate (weekday)",
  "Contact rate (weekend)"
)

stats_names <- c(
  "Time to peak",
  "Size of peak",
  "Mean (cases)",
  "Standard deviation (cases)"
)

#' Define the LFMCMC simulation function
#'
#' @description
#' `lfmcmc_simulation_fun` defines the simulation function for LFMCMC.
#'
#' @details
#' In LFMCMC, the simulation function run the model with the proposed
#' parameters and returns a simulated dataset that looks like the
#' observed dataset. This simulation function runs the SIR CONN
#' model created in earlier steps with the given model parameters,
#' adjusting contact rates for weekday vs weekend and adjusting
#' transmission rates based on the season. It then returns a set
#' of COVID-19 case counts for the same period as the observed case
#' counts.
#'
#' @param params Vector of numeric model parameters.
#' @param lfmcmc_obj Object of class [LFMCMC].
#'
#' @returns A simulated set of COVID-19 case counts.
lfmcmc_simulation_fun <- function(params, lfmcmc_obj) {
  # Extract parameters
  r_rate          <- params[1]
  t_rate_spring   <- params[2]
  t_rate_summer   <- params[3]
  t_rate_fall     <- params[4]
  t_rate_winter   <- params[5]
  c_rate_weekday  <- params[6]
  c_rate_weekend  <- params[7]

  # Set recovery rate
  set_param(covid_sirconn_model, "Recovery rate", r_rate)

  # Global event to change contact and transmission rates
  change_c_and_t_rates <- function(model) {
    # Get the current model day (step)
    current_model_day <- today(model)

    ## Update contact rate based on weekday/weekend
    if (any(c(6, 0) %in% (current_model_day %% 7L))) {
      set_param(model, "Contact rate", c_rate_weekend)
    } else {
      set_param(model, "Contact rate", c_rate_weekday)
    }

    ## Update transmission rate each season
    if (current_model_day == seasons[["spring"]]) {
      set_param(model, "Transmission rate", t_rate_spring)
    } else if (current_model_day == seasons[["summer"]]) {
      set_param(model, "Transmission rate", t_rate_summer)
    } else if (current_model_day == seasons[["fall"]]) {
      set_param(model, "Transmission rate", t_rate_fall)
    } else if (current_model_day == seasons[["winter"]]) {
      set_param(model, "Transmission rate", t_rate_winter)
    }

    invisible(model)
  }

  # Add global event to the model
  change_c_and_t_event_name <- "Change Contact and Transmission Rates"
  globalevent_fun(change_c_and_t_rates, name = change_c_and_t_event_name) |>
    add_globalevent(model = covid_sirconn_model)

  # Run the model
  verbose_off(covid_sirconn_model)
  run(covid_sirconn_model, ndays = model_ndays)

  # Remove global event (new event set each simulation run)
  rm_globalevent(covid_sirconn_model, change_c_and_t_event_name)

  # Get infected cases
  hist_matrix <- get_hist_transition_matrix(covid_sirconn_model)
  # - Drop the last day of data because the model returns data for (model_ndays + 1) days
  infected_cases <- head(
    hist_matrix[
      hist_matrix$state_to == "Infected" &
        hist_matrix$state_from == "Susceptible",
      c("counts")],
    -1
  )

  return(as.double(infected_cases))
}

# Create the LFMCMC object
calibration_lfmcmc <- LFMCMC(covid_sirconn_model) |>
  set_simulation_fun(lfmcmc_simulation_fun) |>
  set_summary_fun(lfmcmc_summary_fun) |>
  set_proposal_fun(lfmcmc_proposal_fun) |>
  set_kernel_fun(lfmcmc_kernel_fun) |>
  set_observed_data(covid_cases)

# Run LFMCMC calibration
verbose_off(calibration_lfmcmc)
run_lfmcmc(
  lfmcmc = calibration_lfmcmc,
  params_init = init_lfmcmc_params,
  n_samples = lfmcmc_n_samples,
  epsilon = lfmcmc_epsilon,
  seed = model_seed
)
set_params_names(calibration_lfmcmc, param_names)
set_stats_names(calibration_lfmcmc, stats_names)

## ----------------------------------
## RUN FORECAST
## ----------------------------------
# Create a new SIR CONN model
# - Compute prevalance based on most recent day
forecast_prevalence <- covid_cases[90] / model_n
# - Init the model
covid_sirconn_model <- ModelSIRCONN(
  name              = "COVID-19",
  n                 = model_n,
  prevalence        = forecast_prevalence,
  contact_rate      = init_contact_rate,
  transmission_rate = init_transmission_rate,
  recovery_rate     = init_recovery_rate
)

# Run the simulation for each set of params in the sample
# - Select sample of accepted params from LFMCMC
forecast_sample_n <- 200 # Sample size
params_sample <- get_params_sample(calibration_lfmcmc,
  lfmcmc_n_samples,
  lfmcmc_burnin,
  forecast_sample_n)
# - Set forecast length
model_ndays <- 14
# - Run simulation function for each set of params from the sample
forecast_dist <- apply(params_sample, 1, lfmcmc_simulation_fun)

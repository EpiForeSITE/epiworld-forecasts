## ----------------------------------
## GENERAL FUNCTIONS
## ----------------------------------
source("forecast-pkg.R")
source("plot-forecast.R")

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

print_lfmcmc_results <- function(lfmcmc_object, burnin) {

  param_names <- c(
    "Recovery rate",
    "Transmission rate (spring)",
    "Transmission rate (summer)",
    "Transmission rate (fall)",
    "Transmission rate (winter)",
    "Contact rate (weekday)",
    "Contact rate (weekend)"
  )
  set_params_names(lfmcmc_object, param_names)

  stats_names <- c(
    "Time to peak",
    "Size of peak",
    "Mean (cases)",
    "Standard deviation (cases)"
  )
  set_stats_names(lfmcmc_object, stats_names)

  print(lfmcmc_object, burnin = burnin)
}

# ## ----------------------------------
# ## RUN FORECAST
# ## ----------------------------------

# init_prevalence <- forecast_data_cases[1] / model_n
# init_contact_rate <- 10
# init_transmission_rate <- 0.05
# init_recovery_rate <- 1 / 7

# # Create the base SIRCONN model
# ef_model <- ModelSIRCONN(
#   name              = "COVID-19",
#   n                 = model_n,
#   prevalence        = init_prevalence,
#   contact_rate      = init_contact_rate,
#   transmission_rate = init_transmission_rate,
#   recovery_rate     = init_lfmcmc_params[1]
# )

# # Set LFMCMC parameters
# lfmcmc_n_samples    <- 6000     # number of LFMCMC iterations
# lfmcmc_n_burnin     <- 2000     # burn-in period
# lfmcmc_epsilon      <- 0.25     # Epsilon for LFMCMC kernel function

# init_lfmcmc_params <- c(
#   init_recovery_rate,   # recovery_rate
#   0.05,                 # t_rate_spring
#   0.04,                 # t_rate_summer
#   0.06,                 # t_rate_fall
#   0.07,                 # t_rate_winter
#   10,                   # contact_rate_weekday
#   2                     # contact_rate_weekend
# )

# # Define LFMCMC functions
# # Define the LFMCMC simulation function
# lfmcmc_simulation_fun <- function(params) {
#   # Extract parameters
#   recovery_rate        <- params[1]
#   t_rate_spring        <- params[2]
#   t_rate_summer        <- params[3]
#   t_rate_fall          <- params[4]
#   t_rate_winter        <- params[5]
#   contact_rate_weekday <- params[6]
#   contact_rate_weekend <- params[7]

#   # Set recovery rate
#   set_param(ef_model, "Recovery rate", recovery_rate)

#   # Global event to change contact and transmission rates
#   change_c_and_t_rates <- function(model) {
#     # Get the current model day (step)
#     current_model_day <- today(model)

#     ## Update contact rate based on weekday/weekend
#     if (any(c(6, 0) %in% (current_model_day %% 7L))) {
#       set_param(model, "Contact rate", contact_rate_weekend)
#     } else {
#       set_param(model, "Contact rate", contact_rate_weekday)
#     }

#     ## Update transmission rate each season
#     if (current_model_day == spring_start) {
#       set_param(model, "Transmission rate", t_rate_spring)
#     } else if (current_model_day == summer_start) {
#       set_param(model, "Transmission rate", t_rate_summer)
#     } else if (current_model_day == fall_start) {
#       set_param(model, "Transmission rate", t_rate_fall)
#     } else if (current_model_day == winter_start) {
#       set_param(model, "Transmission rate", t_rate_winter)
#     }

#     invisible(model)
#   }

#   # Add global event to the model
#   change_c_and_t_event_name <- "Change Contact and Transmission Rates"
#   globalevent_fun(change_c_and_t_rates, name = change_c_and_t_event_name) |>
#     add_globalevent(model = ef_model)

#   # Run the model
#   verbose_off(ef_model)
#   run(ef_model, ndays = model_ndays)

#   # Remove global event (new event set each simulation run)
#   rm_globalevent(ef_model, change_c_and_t_event_name)

#   # Get infected cases
#   hist_matrix <- get_hist_transition_matrix(ef_model)
#   # - Drop the last day of data because the model returns data for (model_ndays + 1) days
#   infected_cases <- head(
#     hist_matrix[
#       hist_matrix$state_to == "Infected" &
#         hist_matrix$state_from == "Susceptible",
#       c("counts")],
#     -1
#   )

#   return(as.double(infected_cases))
# }

# # Define the LFMCMC summary function
# lfmcmc_summary_fun <- function(case_counts) {
#   # Extract summary statistics from the data
#   time_to_peak <- which.max(case_counts)
#   size_of_peak <- case_counts[time_to_peak]
#   mean_cases <- mean(case_counts)
#   sd_cases <- sd(case_counts)

#   c(
#     time_to_peak,
#     size_of_peak,
#     mean_cases,
#     sd_cases
#   )
# }

# # Define the LFMCMC summary function
# lfmcmc_proposal_fun <- function(params_prev) {
#   # Propose new model parameters
#   params_1_to_5 <- plogis(
#     qlogis(params_prev[1:5]) +
#       rnorm(length(params_prev[1:5]), mean = 0, sd = 0.025)
#   )

#   params_6_to_7 <- params_prev[6:7] +
#     rnorm(2, mean = 0, sd = 0.025)


#   # Reflect contact rates
#   if (params_6_to_7[1] < 0) {
#     params_6_to_7[1] <- params_prev[6] -
#       (params_6_to_7[1] - params_prev[6])
#   }
#   if (params_6_to_7[2] < 0) {
#     params_6_to_7[2] <- params_prev[7] -
#       (params_6_to_7[2] - params_prev[7])
#   }

#   # Return proposed parameters
#   c(params_1_to_5, params_6_to_7)
# }

# # Define the LFMCMC kernel function
# # - Weighs simulation results against observed data
# lfmcmc_kernel_fun <- function(simulated_stats, observed_stats, epsilon) {
#   diff <- ((simulated_stats - observed_stats)^2)^epsilon
#   dnorm(sqrt(sum(diff)))
# }

# # Create the LFMCMC model
# lfmcmc_model <- LFMCMC(ef_model) |>
#   set_simulation_fun(lfmcmc_simulation_fun) |>
#   set_summary_fun(lfmcmc_summary_fun) |>
#   set_proposal_fun(lfmcmc_proposal_fun) |>
#   set_kernel_fun(lfmcmc_kernel_fun) |>
#   set_observed_data(forecast_data_cases)

# run_lfmcmc(
#   lfmcmc = lfmcmc_model,
#   params_init_ = init_lfmcmc_params,
#   n_samples_ = n_samples,
#   epsilon_ = lfmcmc_epsilon,
#   seed = model_seed
# )

# # Print the results with 50% burnin
# param_names <- c(
#   "Recovery rate",
#   "Transmission rate (spring)",
#   "Transmission rate (summer)",
#   "Transmission rate (fall)",
#   "Transmission rate (winter)",
#   "Contact rate (weekday)",
#   "Contact rate (weekend)"
# )
# set_params_names(lfmcmc_model, param_names)

# stats_names <- c(
#   "Time to peak",
#   "Size of peak",
#   "Mean (cases)",
#   "Standard deviation (cases)"
# )
# set_stats_names(lfmcmc_model, stats_names)

# # print(lfmcmc_model, burnin = lfmcmc_n_burnin)

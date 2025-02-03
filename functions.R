## --------------------------------------------------------------------
## LIBRARIES
## --------------------------------------------------------------------

library(epiworldR)
library(ggplot2)
library(tidyr)


## --------------------------------------------------------------------
## GATHER DATA
## --------------------------------------------------------------------

#' Download data from a URL
#'
#' @description
#' `get_data_from_url` downloads a CSV file from a URL and returns the file's data.
#'
#' @details
#' Downloads a zip archive from the given 'data_url',
#' selects the CSV file matching 'target_file' from the zip archive,
#' extracts the data from the target CSV file, and returns the data.
#'
#' @param data_url String URL pointing to the data file (zip archive).
#' @param target_file String filename of a CSV file in the zip archive.
#'
#' @returns The contents of the CSV data in `target_file` using `read.csv()`
get_data_from_url <- function(data_url, target_file) {
  tryCatch({
    # Download the zipped data
    temp_file <- tempfile()
    download.file(data_url, temp_file)
    # Select the appropriate data file
    datafile_name <- grep(
      target_file,
      unzip(temp_file, list = TRUE)$Name,
      ignore.case = TRUE,
      value = TRUE
    )
    datafile <- unz(temp_file, datafile_name)
    # Extract the data
    collected_data <- read.csv(datafile)
    return(collected_data)
  },
  error = function(cond) {
    message("Error: ", conditionMessage(cond))
    return(-1)
  },
  warning = function(cond) {
    message("Warning: ", conditionMessage(cond))
    return(-2)
  },
  finally = {
    # Cleanup
    unlink(temp_file)
  }
  )
}

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


## --------------------------------------------------------------------
## PROCESS DATA
## --------------------------------------------------------------------

#' Get the season of a given date
#'
#' @description
#' `get_date_season` returns the season (spring, summer, fall, winter) for the given date.
#'
#' @param date Date object.
#'
#' @returns A string representing the season for the given date:
#' "spring", "summer", "fall", or "winter"
get_date_season <- function(date) {
  date_month <- as.integer(format(as.Date(date, format = "%d/%m/%Y"), "%m"))

  if (date_month >= 3 && date_month <= 5) {
    return("spring")
  } else if (date_month >= 6 && date_month <= 8) {
    return("summer")
  } else if (date_month >= 9 && date_month <= 11) {
    return("fall")
  } else {
    return("winter")
  }
}

#' Get start date of each season from a list of dates
#'
#' @description
#' `get_season_starts` returns the start of each season (spring, summer,
#' fall, winter) from a list of dates
#'
#' @details
#' This function takes a list of Date objects in chronological order and uses
#' the [get_date_season] function assign a season to each date in the list.
#' The function then finds the position of the first instance of each season
#' in the list, returning a dictionary of four integer values corresponding to
#' the start of each season. The dictionary values are accessed using the
#' lowercase string name of the season ("spring", "summer", "fall",
#' or "winter"). If no match was found, the value of the season start
#' will be '-1'.
#'
#' @param dates A list of Date objects in chronological order.
#'
#' @returns A dictionary containing the starting positiong of
#' each season, accessed with the lowercase string name of
#' the season ("spring", "summer", "fall", or "winter").
get_season_starts <- function(dates) {
  seasons <- mapply(get_date_season, dates)
  season_names <- c("spring", "summer", "fall", "winter")

  spring_start <- match(season_names[1], seasons, nomatch = -1)
  summer_start <- match(season_names[2], seasons, nomatch = -1)
  fall_start <- match(season_names[3], seasons, nomatch = -1)
  winter_start <- match(season_names[4], seasons, nomatch = -1)

  season_starts <- c(spring_start, summer_start, fall_start, winter_start)
  names(season_starts) <- season_names

  return(season_starts)
}





## --------------------------------------------------------------------
## MODEL CALIBRATION
## --------------------------------------------------------------------

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

## --------------------------------------------------------------------
## FORECAST VISUALIZATIONS
## --------------------------------------------------------------------

#' Plot observed COVID-19 data from UDHHS
#'
#' @description
#' `plot_covid_data` plots the COVID-19 dataset downloaded from UDHHS.
#'
#' @details
#' This function uses `ggplot` to plot the COVID-19 data
#' as a time-series with Date along the x-axis and
#' case counts along the y-axis.
#'
#' @param data The data to plot.
#'
#' @returns The plot of the data.
plot_covid_data <- function(data) {
  ggplot(data, aes(x = Date, y = Daily.Cases)) +
    geom_line() +
    labs(x = "Date", y = "Daily Cases") +
    theme_classic()
}

#' Plot posterior distribution of model parameters
#'
#' @description
#' `plot_lfmcmc_post_dist` plots posterior distribution of the
#' model parameters accepted during calibration.
#'
#' @details
#' This function plots the distribution of accepted parameters
#' from the calibration run of LFMCMC. It also plots a
#' vertical line representing the initial parameter value.
#'
#' @param lfmcmc_object Object of class [LFMCMC] which performed the simulation.
#' @param init_params Vector of the initial parameter values.
#' @param param_names The string names of the parameters.
#' @param seasons The dictionary of season start positions.
#'
#' @returns The plot of the posterior distribution of model parameters.
plot_lfmcmc_post_dist <- function(
  lfmcmc_object,
  init_params,
  param_names,
  seasons
  ) {

  accepted_params <- get_all_accepted_params(lfmcmc_object)
  accepted_params <- lapply(seq_along(param_names), \(i) {
    data.frame(
      step  = seq_len(nrow(accepted_params)),
      param = param_names[i],
      value = accepted_params[, i]
    )
  }) |> do.call(what = "rbind")

  # Select transmission rates to plot
  t_params_used <- character()
  t_values_used <- numeric()
  if (seasons[["spring"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[2])
    t_values_used <- c(t_values_used, init_params[2])
  }
  if (seasons[["summer"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[3])
    t_values_used <- c(t_values_used, init_params[3])
  }
  if (seasons[["fall"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[4])
    t_values_used <- c(t_values_used, init_params[4])
  }
  if (seasons[["winter"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[5])
    t_values_used <- c(t_values_used, init_params[5])
  }

  # Extract transmission, recovery, and contact rates
  t_rates <- accepted_params[accepted_params$param == t_params_used, ]
  r_rate <- accepted_params[accepted_params$param == param_names[1], ]
  c_rates <- accepted_params[accepted_params$param == param_names[6:7], ]
  t_r_c_rates <- rbind(r_rate, c_rates, t_rates)

  # Generate initial values for vertical lines in each plot
  init_values <- c(init_params[6],
    init_params[7],
    init_params[1],
    t_values_used)

  init_names <- c(param_names[6],
    param_names[7],
    param_names[1],
    t_params_used)

  init_df <- data.frame(param = init_names,
    value = init_values)

  # Plot parameter distributions
  ggplot(t_r_c_rates, aes(x = value,
    fill = param,
    y = after_stat(scaled))) +
    geom_density(alpha = .3) +
    geom_vline(aes(xintercept = value, color = param),
      data = init_df) +
    facet_wrap(~param, scales = "free", ncol = 1) +
    theme_light()

}

#' Plot forecasted COVID-19 case counts
#'
#' @description
#' `plot_forecast` plots the forecasted COVID case counts with 50% and 95% confidence intervals.
#'
#' @details
#' This function plots the observed COVID-19 case count data from
#' the last 30 days (in black), appending to the end of this data the
#' forecasted case counts (in blue). It also plots the 50% and 95%
#' confidence intervals for the forecasted case counts.
#'
#' @param forecast_dist An array of forecasted case counts.
#' @param covid_data A data frame of observed COVID-19 case counts.
#'
#' @returns The plot of the forecasted COVID-19 case counts.
plot_forecast <- function(
  forecast_dist,
  covid_data,
  c(0.025, 0.25, 0.5, 0.75, 0.975)
  ) {

  # Find 2.5%, 25%, 50%, 75%, and 97.5% quantiles
  forecast_quantiles <- apply(
    forecast_dist, 1,
    quantile,
    probs = probs
    )

  # Combine observed data with sample median for plotting forecast
  observed_df <- data.frame(
    date = covid_data$Date[60:90],
    counts = covid_data$Daily.Cases[60:90],
    observed = TRUE,
    lb_95 = NA,
    ub_95 = NA,
    lb_50 = NA,
    ub_50 = NA
  )
  sample_df <- data.frame(
    date = covid_data$Date[90] + 0:13,
    counts = forecast_quantiles["50%", ],
    observed = FALSE,
    lb_95 = forecast_quantiles["2.5%", ],
    ub_95 = forecast_quantiles["97.5%", ],
    lb_50 = forecast_quantiles["25%", ],
    ub_50 = forecast_quantiles["75%", ]
  )

  forecast_df <- rbind(observed_df, sample_df)

  # Use color-blind-friendly palette:
  cbb_light_blue <- "#56B4E9"
  cbb_palette <- c(cbb_light_blue, "black")

  ggplot(forecast_df,
    aes(x = date)) +
    geom_ribbon(aes(ymin = lb_95, ymax = ub_95),
      fill = cbb_light_blue,
      alpha = 0.4,
      na.rm = TRUE) +
    geom_ribbon(aes(ymin = lb_50, ymax = ub_50),
      fill = cbb_light_blue,
      alpha = 0.4,
      na.rm = TRUE) +
    geom_point(aes(y = counts,
      color = observed)) +
    geom_line(aes(y = counts,
      color = observed)) +
    labs(x = "Date", y = "Daily Cases") +
    scale_colour_manual(
      values = cbb_palette,
      labels = c("Forecasted Cases (median)", "Observed Cases")
      ) +
    scale_y_continuous(n.breaks = 20) +
    theme_bw()
}

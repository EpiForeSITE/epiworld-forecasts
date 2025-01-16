# Needed libraries
library(ggplot2)

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
plot_lfmcmc_post_dist <- function(lfmcmc_object, init_params, param_names, seasons) {

  accepted_params <- get_accepted_params(lfmcmc_object)
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
plot_forecast <- function(forecast_dist, covid_data) {
  # Find 2.5%, 25%, 50%, 75%, and 97.5% quantiles
  forecast_quantiles <- apply(forecast_dist, 1, quantile, probs = c(0.025, 0.25, 0.5, 0.75, 0.975))

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
    scale_colour_manual(values = cbb_palette,
      labels = c("Forecasted Cases", "Observed Cases")) +
    scale_y_continuous(n.breaks = 20) +
    theme_bw()
}

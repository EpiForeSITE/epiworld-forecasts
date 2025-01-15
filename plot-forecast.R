# Needed libraries
library(ggplot2)

# Plot forecast data
# In Quarto, plotted this with:
#| fig-width: 7
#| fig-height: 3
#| fig-align: center
plot_covid_data <- function(data) {
  ggplot(data, aes(x = Date, y = Daily.Cases)) +
    geom_line() +
    labs(x = "Date", y = "Daily Cases") +
    theme_classic()
}

# Plot posterior distribution of model parameters
plot_lfmcmc_post_dist <- function(lfmcmc_object, param_names, init_lfmcmc_params, seasons) {

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
    t_values_used <- c(t_values_used, init_lfmcmc_params[2])
  }
  if (seasons[["summer"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[3])
    t_values_used <- c(t_values_used, init_lfmcmc_params[3])
  }
  if (seasons[["fall"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[4])
    t_values_used <- c(t_values_used, init_lfmcmc_params[4])
  }
  if (seasons[["winter"]] >= 0) {
    t_params_used <- c(t_params_used, param_names[5])
    t_values_used <- c(t_values_used, init_lfmcmc_params[5])
  }

  # Extract transmission, recovery, and contact rates
  t_rates <- accepted_params[accepted_params$param == t_params_used, ]
  r_rate <- accepted_params[accepted_params$param == param_names[1], ]
  c_rates <- accepted_params[accepted_params$param == param_names[6:7], ]
  t_r_c_rates <- rbind(r_rate, c_rates, t_rates)

  # Generate initial values for vertical lines in each plot
  init_values <- c(init_lfmcmc_params[6],
    init_lfmcmc_params[7],
    init_lfmcmc_params[1],
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

# Plot forecast
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

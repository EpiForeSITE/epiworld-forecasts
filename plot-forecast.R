# Needed libraries
library(ggplot2)

# Plot forecast data
# In Quarto, plotted this with:
#| fig-width: 7
#| fig-height: 3
#| fig-align: center
# TODO: rename forecast data to observed data/existing data/etc
plot_covid_data <- function(data) {
  ggplot(data, aes(x = Date, y = Daily.Cases)) +
    geom_line() +
    labs(x = "Date", y = "Daily Cases") +
    theme_classic()
}

# Plot posterior distribution of model parameters
# TODO: pass in season start values
plot_post_dist_model_params <- function(lfmcmc_model, param_names, init_lfmcmc_params) {

  accepted_params <- get_accepted_params(lfmcmc_model)
  accepted_params <- lapply(seq_along(param_names), \(i) {
    data.frame(
      step  = seq_along(nrow(accepted_params)),
      param = param_names[i],
      value = accepted_params[, i]
    )
  }) |> do.call(what = "rbind")

  # Select transmission rates to plot
  t_params_used <- character()
  t_values_used <- numeric()
  if (spring_start >= 0) {
    t_params_used <- c(t_params_used, param_names[2])
    t_values_used <- c(t_values_used, init_lfmcmc_params[2])
  }
  if (summer_start >= 0) {
    t_params_used <- c(t_params_used, param_names[3])
    t_values_used <- c(t_values_used, init_lfmcmc_params[3])
  }
  if (fall_start >= 0) {
    t_params_used <- c(t_params_used, param_names[4])
    t_values_used <- c(t_values_used, init_lfmcmc_params[4])
  }
  if (winter_start >= 0) {
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

# Needed libraries
library(ggplot2)

# Plot forecast data
# TODO: rename forecast data to observed data/existing data/etc
plot_forecast_data <- function(forecast_data) {
  ggplot(forecast_data, aes(x = Date, y = Daily.Cases)) +
    geom_line() +
    labs(x = "Date", y = "Daily Cases") +
    theme_classic()
}

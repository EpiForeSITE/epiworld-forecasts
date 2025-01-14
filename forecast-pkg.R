# Needed libraries
library(epiworldR)

# Downloads data from the given 'url' and
# extracts the data file that matches the 'target_file'
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
    forecast_data <- read.csv(datafile)
    return(forecast_data)
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

# Function to get the season for a given date
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

# Function to get start date for each season from an array of dates
# - This assumes the dates are chronologically organized
get_season_starts <- function(dates) {
  seasons <- mapply(get_date_season, dates)
  season_names <- c("spring", "summer", "fall", "winter")

  spring_start <- match(season_names[1], forecast_seasons, nomatch = -1)
  summer_start <- match(season_names[2], forecast_seasons, nomatch = -1)
  fall_start <- match(season_names[3], forecast_seasons, nomatch = -1)
  winter_start <- match(season_names[4], forecast_seasons, nomatch = -1)

  season_starts <- c(spring_start, summer_start, fall_start, winter_start)
  names(season_starts) <- season_names

  return(season_starts)
}

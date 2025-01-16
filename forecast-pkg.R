# Needed libraries
library(epiworldR)

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

# Downloads data from the given 'url' and
# extracts the data file that matches the 'target_file'
get_forecast_data <- function(data_url, target_file) {
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

# Download the zipped data from Utah DHHS
data_url <- "https://coronavirus-dashboard.utah.gov/Utah_COVID19_data.zip"
temp_file <- tempfile()
download.file(data_url, temp_file)
# Extract the appropriate data file
target_file_regex <- "Trends_Epidemic+"
datafile_name <- grep(
  target_file_regex,
  unzip(temp_file, list = TRUE)$Name,
  ignore.case = TRUE,
  value = TRUE
)
datafile <- unz(temp_file, datafile_name)
# Extract the data
forecast_data <- read.csv(datafile)
# Cleanup
unlink(temp_file)

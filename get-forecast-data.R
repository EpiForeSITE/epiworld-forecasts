# Download the zipped data from Utah DHHS
temp <- tempfile()
download.file(
  "https://coronavirus-dashboard.utah.gov/Utah_COVID19_data.zip",
  temp
)
# Extract the appropriate data file
datafile_name <- grep(
  "Trends_Epidemic+",
  unzip(temp, list = TRUE)$Name,
  ignore.case = TRUE,
  value = TRUE
)
datafile <- unz(temp, datafile_name)
# Extract the data
forecast_data <- read.csv(datafile)
# Cleanup
unlink(temp)

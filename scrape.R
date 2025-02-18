# Purpose: retrieve human case data from the web
library(rvest)
library(data.table)
library(here)
uri <- "https://www.cdc.gov/bird-flu/situation-summary/index.html"

# read the html
page <- read_html(uri)

# find the button element and extract its href
# Human cases

# Use chromote for browser automation
library(chromote)

# Start a new browser session
b <- ChromoteSession$new()

# Navigate to the page
b$Page$navigate(uri)
Sys.sleep(2)  # Give page time to load

# Enable download handling
b$Browser$setDownloadBehavior(
  behavior = "allow",
  downloadPath = tempdir()
)

# Click the download button using JavaScript
b$Runtime$evaluate("
  document.querySelector('a[download=\"data-table.csv\"]').click();
")

# Wait briefly for download
Sys.sleep(3)

# Find the downloaded file
csv_file <- list.files(
  path = tempdir(),
  pattern = "data-table\\.csv$",
  full.names = TRUE
)[1]

# Read and process the data
if (!is.na(csv_file)) {
  csv_data <- fread(csv_file)
  csv_data[, UpdateDTS := Sys.time()]
  
  # Write to destination
  table_dt_long <- melt(csv_data, id.vars = c("State"), variable.name = "Source", value.name = "Cases")

table_dt_long[, Cases := as.numeric(Cases)]
table_dt_long[, UpdateDTS := Sys.time()]
fwrite(table_dt_long, here("data-raw", "human_cases.csv"), append = TRUE)
  
  # Clean up
  file.remove(csv_file)
}

# Close the browser
b$close()



# Get WW data

url <- "https://www.cdc.gov/wcms/vizdata/NCEZID_DIDRI/FluA/H5N1Table.json"
library(httr)
tmp <- tempfile()
httr::GET(url, write_disk(tmp))

dat <- jsonlite::fromJSON(tmp)

dat$UpdateDTS <- Sys.time()

dat_long <- dat |>
  tidyr::gather(DateDT, StatusDT, -Sewershed, -`State/Territory`, -County, -UpdateDTS)

fwrite(dat_long, here("data-raw", "ww_cases.csv"), append = TRUE)



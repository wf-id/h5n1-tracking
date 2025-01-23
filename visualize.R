library(data.table)
library(jsonlite)

# Helper function to load and prepare data
load_case_data <- function() {
  fat <- fread("data-raw/human_cases.csv")
  return(fat)
}

# Add this function to handle UTF-8 conversion
convert_to_utf8 <- function(input_file, output_file) {
  # Read the file with detection of encoding
  data <- readLines(input_file, encoding = "latin1", warn = FALSE)
  
  # Write back in UTF-8
  writeLines(data, output_file, useBytes = TRUE)
}

# Convert the files
dat_dairy <- read.csv("data-raw/dairy_tracking.csv", sep="\t", fileEncoding = "UCS-2LE", stringsAsFactors=FALSE) |>
  as.data.table()

dat_poultry <- read.csv("data-raw/poultry_tracking.csv", sep="\t", fileEncoding = "UCS-2LE", stringsAsFactors=FALSE) |>
  as.data.table()


total_cases <- load_case_data()[State == "Source Total" & Source == "State Total"]

# Function to create the time series plot
create_cases_plot <- function(data, log_scale = FALSE) {
  total_cases <- data[State == "Source Total" & Source == "State Total"]
  
  p <- ggplot(total_cases, aes(x = UpdateDTS, y = Cases)) +
    geom_line(color = "#2c5282", size = 1) +
    theme_minimal() +
    labs(
      title = "Human Cases Over Time",
      x = "Date",
      y = if(log_scale) "Cases (Log Scale)" else "Cases"
    ) +
    theme(
      plot.title = element_text(size = 16, face = "bold"),
      axis.title = element_text(size = 12)
    )
    
  if(log_scale) {
    p <- p + scale_y_log10()
  }
  
  return(p)
}

# Convert to JSON
json_data <- toJSON(
  list(
    dates = format(total_cases$UpdateDTS, "%Y-%m-%d"),
    cases = total_cases$Cases,
    log_cases = log(total_cases$Cases)
  ),
  auto_unbox = TRUE
)

# Write to file
writeLines(json_data, here::here("docs", "data.json"))

# Dairy ------------------------------------------

dat_dairy[,.(Cases = .N), by = .(Confirmed, State)]

generate_dairy_json <- function(dat_dairy) {
  z <- dat_dairy[,.(Cases = .N), by = .(Confirmed, State)]
  z[order(Confirmed, State)]

  toJSON(
  list(
    dates = z$Confirmed,
    cases = z$Cases,
    states = z$State
  ),
  auto_unbox = TRUE
)
}

generate_poultry_json <- function(dat_poultry) {
  z <- dat_poultry[,.(Cases = .N), by = .(Confirmed, State)][
    ,Confirmed := as.Date(Confirmed, "%d-%b-%y")
  ]
  z <- z[order(Confirmed, State)]

  toJSON(
  list(
    dates = z$Confirmed,
    cases = z$Cases,
    states = z$State
  ),
  auto_unbox = TRUE
)
}
generate_poultry_json(dat_poultry)

writeLines(generate_dairy_json(dat_dairy), here::here("docs", "dairy_data.json"))
writeLines(generate_poultry_json(dat_poultry), here::here("docs", "poultry_data.json"))
dat_ww <- fread(here::here("data-raw", "ww_cases.csv"))

dat_ww[,DateDT := as.Date(DateDT, "%m/%d/%Y")]

# Process wastewater data and convert to JSON format
process_ww_data <- function(dat_ww) {
  pos <- copy(dat_ww)[,Status := fcase(StatusDT == "+", 1,
                                     StatusDT == "-", 0,
                                     default = NA)]
  
  positivity_data <- pos[`State/Territory` %in% unique(pos[Status > 0]$`State/Territory`)][
    ,.(Pct = mean(Status, na.rm = TRUE)), 
    by = .(DateDT, `State/Territory`)]
  
  # Create a nested list structure that's easier to use in JavaScript
  data_by_state <- split(positivity_data, positivity_data$`State/Territory`)
  formatted_data <- lapply(data_by_state, function(state_data) {
    state_data[order(DateDT)]$Pct
  })
  
  # Convert to JSON format
  ww_json <- toJSON(
    list(
      dates = format(sort(unique(positivity_data$DateDT)), "%Y-%m-%d"),
      states = names(formatted_data),
      data = formatted_data
    ),
    auto_unbox = TRUE
  )
  
  # Write wastewater data to JSON file
  writeLines(ww_json, "docs/ww_data.json")
}

# Call the function
process_ww_data(dat_ww)


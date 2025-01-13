library(data.table)
library(jsonlite)

# Helper function to load and prepare data
load_case_data <- function() {
  fat <- fread("data-raw/human_cases.csv")
  return(fat)
}

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


library(shiny)
library(data.table)
library(ggplot2)

# Source the visualization functions
source("visualize.R")

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  
  # Header
  titlePanel("Human Cases Dashboard"),
  
  # Sidebar with controls
  sidebarLayout(
    sidebarPanel(
      checkboxInput("log_scale", "Use Log Scale", value = TRUE),
      width = 3
    ),
    
    # Main panel with plots and data
    mainPanel(
      plotOutput("timeseries_plot", height = "400px"),
      br(),
      h3("Data Summary"),
      tableOutput("summary_table"),
      width = 9
    )
  )
)

server <- function(input, output) {
  # Load data once
  data <- reactive({
    load_case_data()
  })
  
  # Create the time series plot
  output$timeseries_plot <- renderPlot({
    create_cases_plot(data(), input$log_scale)
  })
  
  # Create summary table
  output$summary_table <- renderTable({
    total_cases <- data()[State == "Source Total" & Source == "State Total"]
    data.frame(
      Metric = c("Total Records", "Latest Case Count", "Maximum Cases", "Minimum Cases"),
      Value = c(
        nrow(total_cases),
        tail(total_cases$Cases, 1),
        max(total_cases$Cases),
        min(total_cases$Cases)
      )
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server) 

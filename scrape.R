# Purpose: retrieve human case data from the web
library(rvest)
library(data.table)

uri <- "https://www.cdc.gov/bird-flu/situation-summary/index.html"

# read the html
page <- read_html(uri)

# extract the table
table <- html_table(page)

table_dt <- setDT(table[[1]])

table_dt_long <- melt(table_dt, id.vars = c("State"), variable.name = "Source", value.name = "Cases")

table_dt_long[, Cases := as.numeric(Cases)]
table_dt_long[, UpdateDTS := Sys.time()]

# write to disk
fwrite(table_dt_long, "data-raw/human_cases.csv", append = TRUE)

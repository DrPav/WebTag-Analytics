#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny) # Dashboard functions
library(dygraphs) #Interactive time series graph
library(dplyr) # Fast data manipulation
library(tidyr)
library(xts)

#Load the data that will be used
#In future make this a RData object for faster loading and smaller filesize
time_data = read.csv("data/historic_time_series.csv")
load("data/historic_geo_data.RData")

#Create the rankings table
#This step should be moved the data transformation stage
rankings_data = historic_geo_data %>% filter(date >= "2016-01-01") %>% group_by(pageTitle, url) %>% 
  summarise(pageviews = sum(pageviews)) %>% as.data.frame() %>% arrange(desc(pageviews))
rankings_data$rank = seq(from = 1, to = length(rankings_data$pageTitle))
rankings_data = rankings_data[,c(4,1,2,3)] # Put rank first

#Convert to R time series
#Again to be done in a outside of the app - need to reduce Url to somethig more readable
time_data$date = as.character(time_data$date)
urls = read.csv("data/names.csv", stringsAsFactors = F)
time_data %<>% inner_join(urls)
ts_pageviews = time_data %>% select(date, ReadableName, pageviews) %>% spread(ReadableName, pageviews)
rownames(ts_pageviews) <- ts_pageviews$date
ts_pageviews$date <- NULL
ts_pageviews %<>% as.matrix()
ts_pageviews %<>% as.xts(dateFormat='Date')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  output$rankingsTable <- renderDataTable(rankings_data, options = list(pageLength = 10))
  
  output$dygraph <- renderDygraph({
    dygraph(ts_pageviews[, "WebTAG appraisal tables"], main = "Predicted Deaths/Month") %>%
      dyRangeSelector()
  })
  
})

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
#library(tidyr)
library(xts)
library(magrittr) #Pipe operators %>% %<>% et.c.

#Load the data that will be used

load("data/dashboard_data.RData")


# Define server logic to make tables and plots
shinyServer(function(input, output) {
   
  output$rankingsTable <- renderDataTable(rankings_data, options = list(pageLength = 10))
  
  output$dygraph <- renderDygraph({
    c1 = ts_pageviews[, input$page1]
    c2 = ts_pageviews[, input$page2]
    c3 = ts_pageviews[, input$page3]
    plot_data = cbind(c1, c2, c3)
    dygraph(plot_data, main = "Daily WebTAG hits") %>%
      dyRangeSelector()
  })
  
  geoData1 = reactive({
    #TODO still need to filter by date outputted by dygraph
    if (input$page1 == "--All--") {
      x = historic_geo_data
    }
    else{
      x = filter(historic_geo_data, pageTitle == input$page1)
    }
    
    if(input$geography == "cities"){
      x %<>% select(City, pageviews) %>% group_by(City) %>% summarise(pageviews = sum(pageviews)) %>% as.data.frame()
    }
    else {
      x %<>% select(Country ,pageviews) %>% group_by(Country) %>% summarise(pageviews = sum(pageviews)) %>% as.data.frame()
    }
    arrange(x, desc(pageviews))
  })
  
  geoData2 = reactive({
    #TODO still need to filter by date outputted by dygraph
    if (input$page2 == "--All--") {
      x = historic_geo_data
    }
    else{
      x = filter(historic_geo_data, pageTitle == input$page2)
    }
    if(input$geography == "cities"){
      x %<>% select(City, pageviews) %>% group_by(City) %>% summarise(pageviews = sum(pageviews)) %>% as.data.frame()
    }
    else {
      x %<>% select(Country ,pageviews) %>% group_by(Country) %>% summarise(pageviews = sum(pageviews)) %>% as.data.frame()
    }
    arrange(x, desc(pageviews))
  })
  
  geoData3 = reactive({
    #TODO still need to filter by date outputted by dygraph
    if (input$page3 == "--All--") {
      x = historic_geo_data
    }
    else{
      x = filter(historic_geo_data, pageTitle == input$page3)
    }
    if(input$geography == "cities"){
      x %<>% select(City, pageviews) %>% group_by(City) %>% summarise(pageviews = sum(pageviews)) %>% as.data.frame()
    }
    else {
      x %<>% select(Country ,pageviews) %>% group_by(Country) %>% summarise(pageviews = sum(pageviews)) %>% as.data.frame()
    }
    arrange(x, desc(pageviews))
  })
  
  output$t1 <- renderUI(h4(input$page1))
  output$t2 <- renderUI(h4(input$page2))
  output$t3 <- renderUI(h4(input$page3))
    
    
  output$geoTable1 <- renderDataTable(geoData1(), options = list(pageLength = 10))
  output$geoTable2 <- renderDataTable(geoData2(), options = list(pageLength = 10))
  output$geoTable3 <- renderDataTable(geoData3(), options = list(pageLength = 10))
  
})

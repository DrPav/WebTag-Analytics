#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

#Choices need to be a named list
#Basic list for now
choices1 = c(1,2,3)
choices2 = c(1,2,3)
choices3 = c(1,2,3)

# Define UI for application that draws a histogram
shinyUI(
  fluidPage(
    # Application title
    titlePanel("WebTAG Hits Dashboard"),
    
    #Some descriptive text under the title
    fluidRow(
      "Some text giving caveats about sampling and instructions"
    ),
    
    #Title of table
    fluidRow(
      h2("Page Rankings"),
         "Page views for 2016"
    ),
    
    #The rankings table
    fluidRow(
      dataTableOutput("rankingsTable")
    ),
    
    #Panel to select up to three series to plot
    fluidRow(
      h2("Interactive Time Series")
    ),
    wellPanel(
      fluidRow(
        "Select the pages you want to plot (up to 3). Select the timeperiod using the mini plot", br(), br()
      ),
      fluidRow(
        column(width = 4, selectInput("page1", "Page 1", choices1)),
        column(width = 4, selectInput("page2", "Page 2", choices2)),
        column(width = 4, selectInput("page3", "Page 3", choices3))
      )
      
    )
 
  )
        
)

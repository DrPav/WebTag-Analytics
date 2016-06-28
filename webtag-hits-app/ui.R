#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(dygraphs)

#Choices of what urls can be selected.
#Data file has two columns
#ReadableName - Name shown to user
#url - the underlying url
cleanTitles = read.csv("data/pageTitles.csv", stringsAsFactors = F)
choices = cleanTitles$pageTitle



# Define UI for application. Fluid row uses the bootstrap grid that has width 12
shinyUI(
  fluidPage(
    # Application title
    column(12, h1("WebTAG Hits Dashboard"), align = "center"),
    
    #Some descriptive text under the title
    fluidRow(
      column(12, "Some text giving caveats about sampling and instructions", offset = 0)
    ),
    
    #Title of table
    fluidRow(
      column(12, offset = 0,
             h2("Page Rankings"),
             "Page views for 2016"
             )
    ),
    
    #The rankings table
    fluidRow(
      column(12, offset = 0, dataTableOutput("rankingsTable"))
    ),
    
    #Title of Timer Series Plot section
    fluidRow(
      column(12, offset = 0, h2("Interactive Time Series"))
    ),
    #Control Panel - Three drop downs spread evenly accross the page
    wellPanel(
      fluidRow(
        "Select the pages you want to plot (up to 3). Select the timeperiod using the mini plot", br(), br()
      ),
      fluidRow(
        column(width = 4, selectInput("page1", "Page 1", choices,
                                      selected = "All")),
        column(width = 4, selectInput("page2", "Page 2", choices,
                                      selected = "None")),
        column(width = 4, selectInput("page3", "Page 3", choices,
                                      selected = "None"))
      )
      
    ),
    #Interactive time series plot
    #http://rstudio.github.io/dygraphs/shiny.html
    fluidRow(
      column(12, offset = 0, dygraphOutput("dygraph"))
    ),
    
    #Title of table breaking data down by geography
    fluidRow(
      column(12, offset = 0, h2("Breakdown by location"))
    ),
    #Option to select either countires of cities as breakdown - radio buttons aligned horizontally
    wellPanel(
      fluidRow(
        column(12, offset = 0,
               radioButtons("geography", "Select geographic breakdown", inline = T,
                            choices = c("countires", "cities")))
      )
    ),
    #Table of results by country of city
    fluidRow(
      column(4, dataTableOutput("geoTable1")),
      column(4, dataTableOutput("geoTable2")),
      column(4, dataTableOutput("geoTable3"))
    )
    
  )
        
)

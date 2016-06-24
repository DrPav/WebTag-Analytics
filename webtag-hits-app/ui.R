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
urls = read.csv("data/names.csv", stringsAsFactors = F)
urls = urls[order(urls$ReadableName),]
choices = as.list(urls$url) %>% setNames(urls$ReadableName)
choices = setNames(choices, urls$ReadableName)
choices = c(None = "no plot", choices)



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
                                      selected = "/government/publications/webtag-tag-overview")),
        column(width = 4, selectInput("page2", "Page 2", choices,
                                      selected = "no plot")),
        column(width = 4, selectInput("page3", "Page 3", choices,
                                      selected = "no plot"))
      )
      
    ),
    #Interactive time series plot
    #http://rstudio.github.io/dygraphs/shiny.html
    fluidRow(
      column(12, offset = 0, dygraphOutput("dygraph"))
    ),
    
    #Title of table breaking data down by geographu
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
      column(12, offset = 0, dataTableOutput("geoTable"))
    )
    
  )
        
)

library(RGoogleAnalytics)
library(lubridate)
library(magrittr)
library(dplyr)

#Authentication
load("auth/token_file")
ValidateToken(token)

#==========================================
#INPUTS
#==========================================
#Pages to get stats for - this will be read from a file
#Extracted urls using www.import.io
url_list_file = "input/webtag urls.txt"

#Data collection period "YYYY-MM-DD" - data is inclusive of these dates
start_date= "2015-11-01"
end_date =  "2016-05-31" 

output_file = "data/historic nov15 - may16.csv"

#==========================================
#FUNCTIONS
#==========================================
#Function to get number of hits and session views for selected page on selected date
#Do one day at a time since it increases the accuracy of the results by decreasing sampling percentage
queryPage <- function(page_url, query_date){
  page_filter = paste0("ga:pagePath==", page_url)
  #Info on query api under this R wrapper
  # https://developers.google.com/analytics/devguides/reporting/core/v3/reference
  my_query = Init(start.date = query_date, #Start and end the same gets on day of data
                  end.date = query_date,
                  dimensions = "ga:date, ga:pageTitle, ga:cityId",
                  metrics = "ga:sessions,ga:pageviews",
                  filters = page_filter,
                  max.results = 10000,
                  sort = "-ga:date", #Not needed as we only expected on result in this query
                  table.id = "ga:53872948") #Id related to our Googla Analytics account
  ga.query <- QueryBuilder(my_query)
  ga.data <- GetReportData(ga.query, token)
  return(ga.data)
}

#Function to loop over a set of dates and return data frame of hits
#For the given page in the time period specified
queryMultipleDates <- function(page_url, start_date, end_date){
  #Page url is a string containng the url part after www.give.uk
  #dates are a string in format "YYYY-MM-DD"
  #Put dates as R Date
  start_date = strptime(start_date, "%Y-%m-%d")
  end_date = strptime(end_date, "%Y-%m-%d") 
  #Calculate the time span in days
  time_diff = difftime(end_date, start_date, units = c("days")) %>% as.numeric()
  #Data Frame to store results
  df1 = data.frame()
  for(x in 0:time_diff){
    query_date =as.character(start_date + days(x))
    result = try(queryPage(page_url, query_date), silent = T)
    #Ignore queries that return a error message string instead of a data frame
    #Error message strings are returned when there are no hits on the selected day
    if(typeof(result) != "character"){ 
      df1 = rbind(df1, result)
      }
  }
  #Add url to the dataframe
  df1$url = page_url
  return(df1)
}

#==========================================
#Execution
#==========================================
#Get the URLS to query
pages = read.csv(url_list_file, header = F, stringsAsFactors = F)$V1
#Remove the gov.uk prefix
pages = sub("https://www.gov.uk", "", pages)

#Loop over the urls and save as a single dataframe
historic_data = data.frame()
for (page in pages){
  result = try(queryMultipleDates(page_url = page, start_date, end_date))
  if(typeof(result) == "list"){#Ignore any errors
    #Convert strings to factors to save memory
    historic_data$url %<>% factor()
    historic_data$pageTitle %<>% factor()
    #Update dataframe
    historic_data = rbind(historic_data, result)
  }
}



#Output to file
write.csv(historic_data, output_file, row.names = F)


#Testing
#===========================
#test = queryPage(pages[1], "2016-05-03") #PASS
#test = queryMultipleDates(pages[1], "2016-05-03", "2016-05-20") #PASS
#Can we go back a year?
#test = queryMultipleDates(pages[1], "2015-05-03", "2015-05-10") #PASS (very slow)
# historic_data %>% group_by(pageTitle) %>% summarise(total = sum(pageviews)) %>% arrange(desc(total) ) #PASS sensible results




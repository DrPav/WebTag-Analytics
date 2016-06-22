library(RGoogleAnalytics)
library(lubridate)
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
start_date= "2016-05-01"
end_date =  "2016-05-31" 

output_file = "data/historic may 2016.csv"

#==========================================
#FUNCTIONS
#==========================================
#Function to get number of hits and session views for selected page on selected date
#Do one day at a time since it increases the accuracy of the results by decreasing sampling percentage
queryPage <- function(page_url, query_date){
  page_filter = paste0("ga:pagePath==", page_url)
  my_query = Init(start.date = query_date, #Start and end the same gets on day of data
                  end.date = query_date,
                  dimensions = "ga:date, ga:pageTitle",
                  metrics = "ga:sessions,ga:pageviews",
                  filters = page_filter,
                  max.results = 10000,
                  sort = "-ga:date", #Not needed as we only expected on result in this query
                  table.id = "ga:53872948") #Id related to our Googla Analytics account
  ga.query <- QueryBuilder(my_query)
  ga.data <- GetReportData(ga.query, token, split_daywise = F)
  return(ga.data)
}

#Function to loop over a set of dates and return data frame of hits
#For the given page in the time period specified
queryMultipleDates <- function(page_url, start_date, end_date){
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
analytics_data = data.frame()
for (page in pages){
  result = try(queryMultipleDates(page_url = page, start_date, end_date))
  if(typeof(result) == "list"){#Ignore any errors
    analytics_data = rbind(analytics_data, result)
  }
}



#Pad the missing dates with pageview,sessions = 0
#Get a list of all possible dates in the timeframe (same format as data ouput)
a = strptime(start_date, "%Y-%m-%d")
b = strptime(end_date, "%Y-%m-%d") 
time_diff = difftime(b, a, units = c("days")) %>% as.numeric()
all_dates = seq(from = 0, to = time_diff, by = 1)
all_dates = lapply(all_dates, function(x) as.character(a + days(x)) )
all_dates = gsub("-", "", all_dates)


#All possible combinations of dates and urls
all_combos = expand.grid(date = all_dates, url = pages, stringsAsFactors = F) %>% as.data.frame()
#Join on the titles for completness
x = analytics_data %>% select(pageTitle, url) %>% distinct()
all_combos = inner_join(all_combos, x)
#Now join on the actual page and session views and replace NAs with zero
all_combos = left_join(all_combos, analytics_data)
all_combos$pageviews[is.na(all_combos$pageviews)] <- 0
all_combos$sessions[is.na(all_combos$sessions)] <- 0
  
  
#Change turn dates into standard format for easier future use
all_combos$date = ymd(all_combos$date)

#Output to file
write.csv(all_combos, output_file, row.names = F)





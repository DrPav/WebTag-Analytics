library(RGoogleAnalytics)

load("token_file")
ValidateToken(token)

test_url = "/government/publications/webtag-tag-unit-a1-1-cost-benefit-analysis-november-2014"
test_url = "/government/collections/tempro"
page_filter = paste0("ga:pagePath==", test_url)


# Build a list of all the Query Parameters
#Valid options for metrics and dimensions are given at:
#https://developers.google.com/analytics/devguides/reporting/core/dimsmets

# ga:pagePath string of the url after gov.uk
# ga:pageviews integer giving the number of pageviews
# ga:city string city from their IP address
# ga:browser
# ga:hour string two digit hour 00 -23

#The table.id was found by running GetProfiles(token)

#I have added the filters. Filter to the selected page only
top_10_june_20 <- Init(start.date = "2016-06-20",
                   end.date = "2016-06-20",
                   dimensions = "ga:pagePath,ga:pageTitle, ga:date",
                   metrics = "ga:sessions,ga:pageviews",
                   #filters = page_filter,
                   max.results = 10,
                   sort = "-ga:pageviews",
                   table.id = "ga:53872948") #

# Create the Query Builder object so that the query parameters are validated
ga.query <- QueryBuilder(top_10_june_20)

# Extract the data and store it in a data-frame
#ga.data <- GetReportData(ga.query, token, split_daywise = T, delay = 5)
ga.data <- GetReportData(ga.query, token, split_daywise = F)

#==============================================================
#Test the ability to filter
#I have added the filters. Filter to the selected page only
top_10_june_20 <- Init(start.date = "2016-05-01",
                       end.date = "2016-05-16",
                       dimensions = "ga:date, ga:pageTitle",
                       metrics = "ga:sessions,ga:pageviews",
                       filters = page_filter,
                       max.results = 10000,
                       sort = "-ga:date",
                       table.id = "ga:53872948") #
ga.query <- QueryBuilder(top_10_june_20)
ga.data <- GetReportData(ga.query, token, split_daywise = T)

#Get an error if there are no page views on a certain date, will have to loop each date manually

#============================================================
#Try looping through the days and adding a try statement to skip if there is no data
library(lubridate)
library(magrittr)

queryPage <- function(page_url, query_date){
  page_filter = paste0("ga:pagePath==", page_url)
  my_query = Init(start.date = query_date,
                  end.date = query_date,
                  dimensions = "ga:date, ga:pageTitle",
                  metrics = "ga:sessions,ga:pageviews",
                  filters = page_filter,
                  max.results = 10000,
                  sort = "-ga:date",
                  table.id = "ga:53872948") 
  ga.query <- QueryBuilder(my_query)
  ga.data <- GetReportData(ga.query, token, split_daywise = F)
  return(ga.data)
}
start_date= "2016-05-01" %>% strptime("%Y-%m-%d")
end_date =  "2016-05-20" %>% strptime("%Y-%m-%d") # No entries for the 17th
time_diff = difftime(end_date, start_date, units = c("days")) %>% as.numeric()
df1 = data.frame()
for(x in 0:time_diff){
  query_date =as.character(start_date + days(x))
  page_url = "/government/collections/tempro"
  print(query_date)
  print("############")
  result = try(queryPage(page_url, query_date), silent = T)
  if(typeof(result) != "character"){
    df1 = rbind(df1, result)
  }
  else{
    print("No results returned for that query")
  }
}




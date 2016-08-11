library(dplyr)
library(magrittr)
library(lubridate)
library(tidyr)
library(xts)
library(RGoogleAnalytics)
library(rdrop2)


#==========================================
#FUNCTIONS TO QUERY GOOGLE ANALYTICS
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
queryMultipleDates <- function(page_url, start_date, end_date, wait = 0){
  #Page url is a string containng the url part after www.give.uk
  #dates are a string in format "YYYY-MM-DD"
  #Wait is number of seconds to wait before performing query
  #Put dates as R Date
  start_date = strptime(start_date, "%Y-%m-%d")
  end_date = strptime(end_date, "%Y-%m-%d") 
  #Calculate the time span in days
  time_diff = difftime(end_date, start_date, units = c("days")) %>% as.numeric()
  time_diff = time_diff + 1 #Bugfix, add one to include the end date
  #Data Frame to store results
  df1 = data.frame()
  
  #Debugging shows that the token perhaps needs to be revalidated of wait in between each query
  print("")
  print(paste("waiting", as.character(wait), "seconds", "-", as.character(Sys.time())))
  Sys.sleep(wait)
  
  print("###########################")
  print("Getting stats on next page")
  print(page_url)
  print("###########################")
  ValidateToken(token)
  for(x in 0:time_diff){
    query_date =as.character(start_date + days(x))
    result = tryCatch(queryPage(page_url, query_date), silent = T, error = function(e) NULL )
    #Returns NULL if there is an errror with the query
    df1 = rbind(df1, result)
  }
  #Check if any results were returned and format and return the df
  if(length(df1) !=  0){
    #Add url to the dataframe
    df1$url = page_url
    #Write to file as backup
    #writeableUrl = gsub("[[:punct:]]", "", page_url)
    #writeableUrl = gsub(" ", "", writeableUrl)
    #temp_file = paste0(data_location, "/",writeableUrl, " ", start_date, " ", end_date, ".csv")
    #write.csv(df1, temp_file, row.names = F)
    return(df1)
  }
  else return(NULL)
}

#==========================================
#FUNCTION TO TRANSFORM THE DATA
#==========================================
cleanData <- function(df1){
  df1 %<>% filter(pageTitle != "Bad request - 400 - GOV.UK")
  df1$pageTitle = gsub(":", "", df1$pageTitle)
  df1$pageTitle = gsub(" - Publications - GOV.UK", "", df1$pageTitle)
  df1$date = ymd(df1$date)
  
  #Add Geo data
  #City definitions
  # https://developers.google.com/analytics/devguides/collection/protocol/v1/geoid
  city_lookup = read.csv("input/google city codes.csv", stringsAsFactors = F) %>% select(cityId = Criteria.ID, City = Name, Country.Code)
  city_lookup$cityId = as.character(city_lookup$cityId)
  #Country definitons
  #https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
  #External links (text file)
  country_lookup = read.csv2("input/iso country codes.txt", stringsAsFactors = F) %>% rename(Country = Country.Name, Country.Code = ISO.3166.1.alpha.2.code )
  #Join city data onto historic data
  historic_geo_data = left_join(df1, city_lookup) %>% left_join(country_lookup)
  
  #Remove some columns and make factors
  historic_geo_data = historic_geo_data %>% select(-cityId, -Country.Code)
  historic_geo_data$City %<>% factor()
  historic_geo_data$Country %<>% factor()
  
  return(historic_geo_data)
}



makeTimeSeries <- function(historic_geo_data){
  #Get a clean time series
  #Pad the missing dates with pageview,sessions = 0
  #Get a list of all possible dates in the timeframe (same format as data ouput)
  first_date = min(historic_geo_data$date)
  last_date = max(historic_geo_data$date)
  time_diff = difftime(last_date, first_date, units = c("days")) %>% as.numeric()
  all_dates = seq(from = 0, to = time_diff, by = 1)
  all_dates = first_date + days(all_dates) 
  #All urls in dataframe
  all_urls = unique(historic_geo_data$url)
  #All possible combinations of dates and urls
  all_combos = expand.grid(date = all_dates, url = all_urls) %>% as.data.frame()
  #Join on the titles for completness
  x = historic_geo_data %>% select(pageTitle, url) %>% distinct()
  all_combos = inner_join(all_combos, x)
  
  #Calculate the daily totals for each page # Ignore city and country
  daily_totals = historic_geo_data %>% group_by(date, pageTitle) %>% summarise(pageviews = sum(pageviews), sessions = sum(sessions)) %>% as.data.frame()
  #Now join with the dataframe o all date page combinations and fill the NAs with zero
  all_combos = left_join(all_combos, daily_totals)
  all_combos$pageviews[is.na(all_combos$pageviews)] <- 0
  all_combos$sessions[is.na(all_combos$sessions)] <- 0
  
  #Convert to R time series
  time_data = all_combos
  time_data$date = as.character(time_data$date)
  ts_pageviews = time_data %>% select(date, pageTitle, pageviews) %>% spread(pageTitle, pageviews)
  rownames(ts_pageviews) <- ts_pageviews$date
  ts_pageviews$date <- NULL
  ts_pageviews["--All--"] <- rowSums(ts_pageviews) #Create a total accross all pages
  ts_pageviews %<>% as.matrix()
  ts_pageviews %<>% as.xts(dateFormat='Date')
}

updateDatabase <- function(dropbox_file){
  
  #dropbox_file = "dashboard_data.RData"

  #First load the dropbox data to see what the most recent date is
  dtoken <- readRDS("auth/webtagdroptoken.rds")
  drop_get(paste0("webtag-app/", dropbox_file), dtoken = dtoken, overwrite = T)
  load(dropbox_file)
  #Loads three dataframes
    #historic_geo_data
    #ts_pageviews
  last_date = max(historic_geo_data$date)
  
  first_day = (last_date + days(1))%>% as.character()
  last_day = (Sys.Date() - days(1)) %>% as.character()
  
  if(first_day >= last_day) stop("Database already up to date. Wait one more day")
  
  #Authentication to google
  load("auth/token_file")
  ValidateToken(token)
  
  #Get the URLS to query
  pages = drop_get("/webtag-app/webtag urls.txt", dtoken = dtoken, overwrite = T)
  pages = read.csv("webtag urls.txt", header = F, stringsAsFactors = F)$V1
  #Remove the gov.uk prefix
  pages = sub("https://www.gov.uk", "", pages)
  
  #Loop over the urls and save as a single dataframe, then join them into one
  x <- lapply(pages, queryMultipleDates, start_date = first_day, end_date = last_day, wait = 10) %>%
    bind_rows() %>% cleanData() %>% rbind(historic_geo_data)
  
  #Add on this new data
  historic_geo_data = rbind(historic_geo_data, x)
  ts_pageviews = makeTimeSeries(historic_geo_data)
  
  #Save as a RData file
  save(historic_geo_data, ts_pageviews, file = dropbox_file)
  #Delete the backup
  drop_delete(paste0("webtag-app/", dropbox_file, ".backup"), dtoken = dtoken)
  #Create a new backup
  drop_copy(from_path = paste0("webtag-app/", dropbox_file), 
            to_path = paste0(dropbox_file, ".backup"), 
            dtoken = dtoken)
  #Load the new data
  drop_upload(dropbox_file, dest = "webtag-app", dtoken = dtoken, overwrite = T )
  
  #Clean the page titles and add extra options for the dashboard
  #================================================================
  readablePages <- filter(historic_geo_data, pageTitle != "Bad request - 400 - GOV.UK") %>% select(pageTitle, url) %>% distinct()
  #Add a none and all option for drop down boxes
  readablePages = rbind(data.frame(pageTitle = c("--None--", "--All--"), url = c("NA", "NA")),readablePages)
  write.csv(readablePages, "pageTitles.csv", row.names = F)
  drop_upload(paste0("webtag-app","pageTitles.csv"), dtoken = dtoken, overwrite = T)
}

makeRankingsTable(historic_geo_data){
#Create the rankings table
#==============================
#Rankings for all since Nov 2015 - edit later to filter by a from date
rankings_data = historic_geo_data %>% group_by(pageTitle, url) %>% 
  summarise(pageviews = sum(pageviews)) %>% as.data.frame() %>% arrange(desc(pageviews))
rankings_data$rank = seq(from = 1, to = length(rankings_data$pageTitle))
rankings_data = rankings_data[,c(4,1,2,3)] # Put rank first
}




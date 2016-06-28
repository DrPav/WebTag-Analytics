#Transform the historic data
library(dplyr)
library(magrittr)
library(lubridate)
library(tidyr)
library(xts)
library(magrittr)

#Load data
data_loc = "data/historic nov15 - may16.csv"
df1 = read.csv(data_loc)
df1$date = ymd(df1$date)
#Cleanup pagetitle
df1 %<>% filter(pageTitle != "Bad request - 400 - GOV.UK")
df1$pageTitle <- gsub(":", "", df1$pageTitle)
df1$pageTitle <- gsub(" - Publications - GOV.UK", "", df1$pageTitle)

#Add Geo data
#City definitions
# https://developers.google.com/analytics/devguides/collection/protocol/v1/geoid
city_lookup = read.csv("data/google city codes.csv", stringsAsFactors = F) %>% select(cityId = Criteria.ID, City = Name, Country.Code)
city_lookup$cityId = as.character(city_lookup$cityId)
#Country definitons
#https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
#External links (text file)
country_lookup = read.csv2("data/iso country codes.txt", stringsAsFactors = F) %>% rename(Country = Country.Name, Country.Code = ISO.3166.1.alpha.2.code )
#Join city data onto historic data
df2 = left_join(df1, city_lookup) %>% left_join(country_lookup)

#Remove some columns and make factors
historic_geo_data = df2 %>% select(-cityId, -Country.Code)
historic_geo_data$City %<>% factor()
historic_geo_data$Country %<>% factor()

#Create the rankings table
#==============================
#Rankings for 2016
rankings_data = historic_geo_data %>% filter(date >= "2016-01-01") %>% group_by(pageTitle, url) %>% 
  summarise(pageviews = sum(pageviews)) %>% as.data.frame() %>% arrange(desc(pageviews))
rankings_data$rank = seq(from = 1, to = length(rankings_data$pageTitle))
rankings_data = rankings_data[,c(4,1,2,3)] # Put rank first


#========================================
#Get a clean time series
#Pad the missing dates with pageview,sessions = 0
#Get a list of all possible dates in the timeframe (same format as data ouput)
first_date = min(df2$date)
last_date = max(df2$date)
time_diff = difftime(last_date, first_date, units = c("days")) %>% as.numeric()
all_dates = seq(from = 0, to = time_diff, by = 1)
all_dates = first_date + days(all_dates) 
#All urls in dataframe
all_urls = levels(df2$url)
#All possible combinations of dates and urls
all_combos = expand.grid(date = all_dates, url = all_urls) %>% as.data.frame()
#Join on the titles for completness
x = df2 %>% select(pageTitle, url) %>% distinct()
all_combos = inner_join(all_combos, x)

#Calculate the daily totals for each page # Ignore city and country
daily_totals = df2 %>% group_by(date, pageTitle) %>% summarise(pageviews = sum(pageviews), sessions = sum(sessions)) %>% as.data.frame()
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
ts_pageviews$All <- rowSums(ts_pageviews) #Create a total accross all pages
ts_pageviews %<>% as.matrix()
ts_pageviews %<>% as.xts(dateFormat='Date')

test = apply.daily(ts_pageviews, sum)

#write.csv(all_combos, "data/historic_time_series.csv", row.names = F)
#===========================================================================

#Output data files for dashboard
save(historic_geo_data, rankings_data, ts_pageviews, file = "webtag-hits-app/data/dashboard_data.RData")

#Clean the page titles and add extra options for the dashboard
#================================================================
readablePages <- filter(historic_geo_data, pageTitle != "Bad request - 400 - GOV.UK") %>% select(pageTitle, url) %>% distinct()
#Add a none and all option for drop down boxes
readablePages = rbind(data.frame(pageTitle = c("None", "All"), url = c("NA", "NA")),readablePages)
write.csv(readablePages, "webtag-hits-app/data/pageTitles.csv", row.names = F)
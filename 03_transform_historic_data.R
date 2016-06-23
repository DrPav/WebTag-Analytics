#Transform the historic data
library(dplyr)
library(magrittr)
library(lubridate)

#Load data
data_loc = "data/historic nov15 - may16.csv"
df1 = read.csv(data_loc)
df1$date = ymd(df1$date)
df1 %<>% filter(pageTitle != "Bad request - 400 - GOV.UK")

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

#Save as a image to use later
historic_geo_data = df2 %>% select(-cityId, -Country.Code)
historic_geo_data$City %<>% factor()
historic_geo_data$Country %<>% factor()

save(historic_geo_data, file = "data/historic_geo_data.RData")

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
daily_totals = df2 %>% group_by(date, pageTitle, url) %>% summarise(pageviews = sum(pageviews), sessions = sum(sessions)) %>% as.data.frame()
#Now join with the dataframe o all date page combinations and fill the NAs with zero
all_combos = left_join(all_combos, daily_totals)
all_combos$pageviews[is.na(all_combos$pageviews)] <- 0
all_combos$sessions[is.na(all_combos$sessions)] <- 0

write.csv(all_combos, "data/historic_time_series.csv", row.names = F)
#===========================================================================
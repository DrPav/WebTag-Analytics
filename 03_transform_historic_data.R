#Transform the historic data

#Start with the dataframe returned by 02_get_historic_data.R
#Need to adapt the code to deal with city data
#City code info
# https://developers.google.com/analytics/devguides/collection/protocol/v1/geoid
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
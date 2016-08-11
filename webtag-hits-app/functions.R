require(dplyr)
makeRankingsTable <- function(historic_geo_data){
  #Create the rankings table
  #==============================
  #Rankings for all since Nov 2015 - edit later to filter by a from date
  rankings_data = historic_geo_data %>% group_by(pageTitle, url) %>% 
    summarise(pageviews = sum(pageviews)) %>% as.data.frame() %>% arrange(desc(pageviews))
  rankings_data$rank = seq(from = 1, to = length(rankings_data$pageTitle))
  rankings_data = rankings_data[,c(4,1,2,3)] # Put rank first
  return(rankings_data)
}
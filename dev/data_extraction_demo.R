library(RGoogleAnalytics)

# Authorize the Google Analytics account
# This need not be executed in every session once the token object is created 
# and saved
token <- Auth(client.id = "246473626117-tvaopdf65gincc6k4enc8arhm9jasihc.apps.googleusercontent.com",
              client.secret = "Ju-EnTxewNMzSvoo92X9koKm")

# Save the token object for future sessions
save(token,file="./token_file")

# In future sessions it can be loaded by running load("./token_file")

ValidateToken(token)

# Build a list of all the Query Parameters
query.list <- Init(start.date = "2013-11-28",
                   end.date = "2013-12-04",
                   dimensions = "ga:date,ga:pagePath,ga:hour,ga:medium",
                   metrics = "ga:sessions,ga:pageviews",
                   max.results = 10000,
                   sort = "-ga:date",
                   table.id = "ga:33093633")

# Create the Query Builder object so that the query parameters are validated
ga.query <- QueryBuilder(query.list)

# Extract the data and store it in a data-frame
ga.data <- GetReportData(ga.query, token, split_daywise = T, delay = 5)
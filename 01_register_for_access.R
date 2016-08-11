library(RGoogleAnalytics)
library(rdrop2)

# Authorize the Google Analytics account
# This need not be executed in every session once the token object is created 
# and saved
client.id = "246473626117-tvaopdf65gincc6k4enc8arhm9jasihc.apps.googleusercontent.com"
client.secret = "XXXXXXXX"

#Select option 2 and then log in on the page that appears
token <- Auth(client.id, client.secret = "XXXXXXXXX")

# Save the token object for future sessions
save(token,file = "auth/token_file")

#DROPBOX - just need to do once like google analytics
token <- drop_auth()
saveRDS(token, "auth/webtagdroptoken.rds")

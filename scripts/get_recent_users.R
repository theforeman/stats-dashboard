# Script to parse the users from the last six months of redmine activity

library(RPostgreSQL)
library(dplyr)
library(dbplyr)
library(lubridate)
library(magrittr)

# Requires the 'config' package
config <- config::get("redmine")
# Access the DB - requires an SSH tunnel to Redmime, e.g.
#   ssh -L 5432:localhost:5432 user@projects.theforeman.org
#
# The credentials should be stored in config.yml in the project root dir
config  <- config::get("redmine")
redmine <- dbConnect(dbDriver(config$driver),
                     dbname   = config$database,
                     host     = config$server,
                     port     = config$port,
                     user     = config$user,
                     password = config$pwd)

# Issues table
issues <- tbl(redmine, 'issues')
journals <- tbl(redmine, 'journals')

# six-month window
d = now() - months(6)

users_i = issues %>%
  filter(created_on > d) %>%
  select(author_id) %>%
  collect() %>%
  rename(user_id = author_id)

users_j = journals %>%
  filter(created_on > d) %>%
  select(user_id) %>%
  collect()

user_ids = rbind(users_i,users_j) %>% distinct() %>% filter(user_id != 2) %>% arrange(user_id)

users = tbl(redmine,'users') %>% filter(id %in% user_ids$user_id) %>% select(id,created_on) %>% collect()

write.csv(users,'/tmp/users.csv',row.names = F)

dbDisconnect(redmine)

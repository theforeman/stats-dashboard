# Script to parse the users from the last six months of redmine activity

library(RPostgreSQL)
library(dplyr)
library(dbplyr)
library(lubridate)
library(magrittr)

# Local copy of the DB
redmine <- dbConnect(dbDriver("PostgreSQL"), dbname='redminedev')

# Issues table
issues <- tbl(redmine, 'issues')

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

library(plotly)

plot_ly(data = users, x = users$created_on, type = 'histogram')

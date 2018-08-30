library(RPostgreSQL)
library(dplyr)
library(dbplyr)
library(lubridate)

# Local copy of the DB
redmine <- dbConnect(dbDriver("PostgreSQL"), dbname='redminedev')

# Issues table
issues <- tbl(redmine, 'issues')

i<- issues %>%
  select(id,project_id,tracker_id,category_id,status_id,fixed_version_id,closed_on,created_on) %>%
  collect()

# Get categories, projects, trackers, status, versions

cats <- tbl(redmine,'issue_categories') %>% select(id,project_id,name) %>% collect()
i <- merge(i,cats,by.x = c('category_id','project_id'), by.y = c('id','project_id'),all.x=T) %>%
  mutate(category = name) %>%
  select(-category_id,-name)
i$category[is.na(i$category)] <- 'Uncategorized'

projs <- tbl(redmine,'projects') %>% filter(status == 1) %>% select(id,name) %>% collect()
i <- merge(i,projs,by.x = 'project_id', by.y = 'id') %>%
  mutate(project = name) %>%
  select(-name)

tracks <- tbl(redmine,'trackers') %>% select(id,name) %>% collect()
i <- merge(i,tracks,by.x = 'tracker_id', by.y = 'id',all.x=T) %>%
  mutate(tracker = name) %>%
  select(-tracker_id,-name)

vers  <- tbl(redmine,'versions') %>% select(id,name,status) %>% collect()
i <- merge(i,vers,by.x = 'fixed_version_id', by.y = 'id',all.x=T) %>%
  mutate(version = name, version_status = status) %>%
  select(-fixed_version_id,-name, -status)

stats <- tbl(redmine,'issue_statuses') %>% select(id,name,is_closed) %>% collect()
i <- merge(i,stats,by.x = 'status_id', by.y = 'id',all.x=T) %>%
  mutate(status = name, is_open = !is_closed) %>%
  select(-status_id,-name,-is_closed)

# Triaged flag is a custom field
triaged_id <- tbl(redmine,'custom_fields') %>%
  filter(name == 'Triaged') %>%
  select(id) %>%
  collect() %>%
  extract2(1,1)

cvs <- tbl(redmine,'custom_values') %>% filter(custom_field_id == triaged_id) %>%
  select(customized_id,value) %>%
  collect() %>%
  group_by(customized_id) %>% #cleanup duplicates
  summarise(value=sum(as.numeric(value),na.rm=T)) %>%
  mutate(value = if_else(value >= 1, 1, 0, 0))
i <- merge(i,cvs,by.x='id',by.y='customized_id',all.x = T) %>%
  mutate(triaged = value) %>%
  select(-value)
i$triaged[is.na(i$triaged)] <- 0
i <- mutate(i, triaged = as.logical(triaged))

write.csv(i,'/tmp/issues.csv',row.names = F)

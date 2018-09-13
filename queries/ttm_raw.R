library(lubridate)

# Helpers - not needed yet
unwrap_labels <- function(.data) {
  .data %>%
    # unwrap the lists of labels
    mutate(labels.edges = map(labels.edges, ~ lapply(., `[[`, 1))) %>%
    # First unnest gives character vectors
    unnest() %>%
    # Second one unnests the rows
    unnest()
}

# Get a list of repos
source('queries/GetRepos.R')

# Build a list of recent PRs for each repo
source('queries/GetRecentIssues.R')
date = Sys.Date() - years(1) #last 6 months
prs_f = get_repos('theforeman') %>%
  group_by(name) %>% #allows 'do' to iterate
  do(get_prs(.$name,owner='theforeman',date=date)) %>%
  filter(!is.na(number)) # removes Issues, leaves PullRequests only

prs_k = get_repos('katello') %>%
  group_by(name) %>% #allows 'do' to iterate
  do(get_prs(.$name,owner='katello',date=date)) %>%
  filter(!is.na(number)) # removes Issues, leaves PullRequests only

prs = bind_rows(prs_f,prs_k)
repositories = bind_rows(repositories,get_repos('katello'))
ttm_raw <- prs %>%
  mutate(merge_time = int_length(interval(createdAt,mergedAt)),
         ttm        = (merge_time/60/60/24)) %>%
  filter(!is.na(merge_time)) %>%
  filter(mergedAt > date) %>%
  select(name,number,authorAssociation,createdAt,mergedAt,author.login,ttm)

# Needed for the GitHub time-to-merge Shiny App
write.csv(ttm_raw,'/tmp/time_to_merge.csv',row.names=F)

# Examples
# PRs by repo and state, and first_time contributor stats
# states = prs %>%
#   group_by(name,state) %>%
#   count() %>%
#   spread(key = state, value = n, fill = 0)
# firsts = prs %>%
#   group_by(name,authorAssociation) %>%
#   count() %>%
#   mutate(is.new = authorAssociation == 'FIRST_TIME_CONTRIBUTOR') %>%
#   filter(is.new == T) %>% ungroup() %>%
#   select(name,n)
# d = merge(states,firsts) %>% rename(NEW = n)
#
# ttm_month = prs %>%
#   filter(!is.na(mergedAt) & mergedAt > date) %>%
#   mutate(month = month(mergedAt),
#          year  = year(mergedAt),
#          merge_time = int_length(interval(createdAt,mergedAt)),
#          date  = ymd(paste0(year,'-',month,'-01'))) %>%
#   group_by(name,date) %>%
#   summarise(n=n(),ttm=round(mean(merge_time)/60/60/24,2))
#
#
# ttm <- prs %>%
#   mutate(merge_time = int_length(interval(createdAt,mergedAt))) %>%
#   filter(!is.na(merge_time)) %>%
#   group_by(name,state) %>% summarise(n=n(),ttm=mean(merge_time))
# ggplot(ttm,aes(x=n,y=(ttm/60/60/24),label=name)) +geom_point() +geom_label()
#
#
# ttm <- ttm %>% mutate(ttm = ttm/60/60/24)
# ttm_month <- ttm_month %>% group_by(name) %>%
#   dplyr::do(model = lm(ttm ~ date, data = .)) %>%
#   tidy(model) %>%
#   filter(term=='date') %>%
#   merge(ttm) %>%
#   mutate(ttm = ttm/60/60/24) %>%
#   select(name,date,estimate,std.error,p.value,n,ttm)

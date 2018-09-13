# GraphQL query to request list of repos for an organisation
# Vars:
#   owner: string: the name to retrieve repositories from
# Output:
#   Class: tibble, 6 vars
# $ name                   : chr
# $ forks.totalCount       : int
# $ issues.totalCount      : int - *open* Issues
# $ pullRequests.totalCount: int - *open* Pull Requests
# $ stargazers.totalCount  : int
# $ watchers.totalCount    : int

library(ghql)
library(jsonlite)
library(httr)
library(dplyr)

get_repos <- function(owner,verbose = FALSE) {
  query_get_repos <- function(owner,after) {
    sprintf('{
      organization(login: %s) {
        repositories(isFork: false, first: 100, %s orderBy: {field: PUSHED_AT, direction: DESC}) {
          pageInfo {
            endCursor
            hasNextPage
          }
          totalCount
          edges {
            node {
              name
              forks { totalCount }
              issues(states:[OPEN]) { totalCount }
              pullRequests(states:[OPEN]) { totalCount }
              stargazers { totalCount }
              watchers { totalCount }
            }
          }
        }
      }
    }',owner,after)
  }

  # Authentication - set a real key here:
  Sys.setenv(GITHUB_GRAPHQL_TOKEN='foobarbaz')
  token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")
  cli <- GraphqlClient$new(
    url = "https://api.github.com/graphql",
    headers = add_headers(Authorization = paste0("Bearer ", token))
  )

  # Storage
  results  = tibble()

  #Pagination
  continue = TRUE
  after    = ''
  progress = 0

  while (continue) {
    # Build query
    qry <- Query$new()
    qry$query('GetRepos',query_get_repos(owner,after))

    result  = fromJSON(cli$exec(qry$queries$GetRepos))
    results = bind_rows(results,jsonlite::flatten(result$data$organization$repositories$edges$node))

    if (verbose) {
      total    = result$data$organization$repositories$totalCount
      print(paste0(progress,'/',total,': ',round(progress/total*100,2),'%'))
      progress = progress + 100
    }

    after    = paste0('after:"',result$data$organization$repositories$pageInfo$endCursor,'",')
    continue = result$data$organization$repositories$pageInfo$hasNextPage
  }

  results
}

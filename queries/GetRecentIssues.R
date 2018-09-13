# GraphQL query to request list of repos for an organisation
# Vars:
#   owner: string: the name to retrieve repositories from
#   repo:  string: the repo to retrieve PRs from
#   date:  string: the date to use for searching on (query is updated_at>date)
# Output:
#   Class: tibble, 13 vars
# $ name                : chr
# $ title               : chr
# $ authorAsociation    : chr
# $ createdAt           : chr
# $ updatesAt           : chr
# $ closedAt            : chr
# $ mergedAt            : chr
# $ state               : chr
# $ mergeable           : chr
# $ author.login        : chr
# $ comments.totalCount : int
# $ labels.totalCount   : int
# $ labels.edges        : List of lists (use the unwrap helper)

library(ghql)
library(jsonlite)
library(httr)
library(dplyr)
library(glue)

get_prs <- function(owner,repo,date,verbose = FALSE) {
  query_get_prs <- function(after,owner,repo,date) {
    sprintf('{
      search(last: 100, %s type: ISSUE, query: "repo:%s/%s updated:>%s") {
        pageInfo {
          endCursor
          hasNextPage
        }
        issueCount
        edges {
          cursor
          node {
            ... on PullRequest {
              number
              title
              authorAssociation
              author { login }
              comments { totalCount }
              createdAt
              updatedAt
              closedAt
              mergedAt
              state
              mergeable
              labels(first: 20) {
                totalCount
                edges {
                  node { name }
                }
              }
            }
          }
        }
      }
    }',after,owner,repo,date)
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

  glue('Processing {repo}')
  while (continue) {
    # Build query
    qry <- Query$new()
    qry$query('GetPRs',query_get_prs(after,owner,repo,date))

    result  = fromJSON(cli$exec(qry$queries$GetPRs))
    if (is.null(result$data$search$issueCount)) { print(result$data) }
    if (result$data$search$issueCount > 0) {
      results = bind_rows(results,jsonlite::flatten(result$data$search$edges$node))

      if (verbose) {
        total    = result$data$search$issueCount
        print(paste0(repo,' - ',progress,'/',total,': ',round(progress/total*100,2),'%'))
        progress = progress + 100
      }

      after    = paste0('after:"',result$data$search$pageInfo$endCursor,'",')
      continue = result$data$search$pageInfo$hasNextPage
    } else {
      continue = FALSE
    }
  }

  results
}

# # examples
# # results %>%
# #  filter(!is.na(mergedAt)) %>%
# #  mutate(ttm = ymd_hms(mergedAt) - ymd_hms(createdAt)) %>%
# #  group_by(comments.totalCount) %>%
# #  summarise(ttm_days=as.numeric(mean(ttm),units='days')) %>%
# #  ggplot(aes(y=ttm_days,x=comments.totalCount)) + geom_point()

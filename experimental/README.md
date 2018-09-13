# Experimental Area

This is an in-devel GitHub API graph for Time To Merge

## Data source

Data is obtained from the GitHub v4 GraphQL API via the two queries in
`queries`. These are called from `queries/ttm_raw.R` which loads all the
Foreman and Katello repos, processes them, and spits out a CSV to
`/tmp/time_to_merge.csv`. You'll need to set a GitHub API token for this to
work.

The Shiny App can be run locally in RStudio or on a Shiny server, but will
expect to find the same `/tmp/time_to_merge.csv` file to load in.

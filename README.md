# Foreman Community Stats

This is a ShinyR webapp for displaying data on the Foreman community.

# Deployment

Follow the [RStudio Shiny Install Guide](http://docs.rstudio.com/shiny-server/#installation)

Once Shiny is up, copy this repo to the appropriate webapp dir (e.g. /srv/shiny-server/foreman)

# Local data

Currently the app uses cached data from our other services. The `scripts` dir
contains the necessary scripts.

### get_issues_from_redmine

This needs to be run against the Redmine DB (either directly on redmine01, or
on an offline DB created from one of the backups). It will output
`/tmp/issues.csv` which can be copied to the stats box.

# Graphs

### Open issues by Category

Currently the only graph, this shows issues where `is_open == TRUE` and then
subsets by `category` and `triaged`. Since we have many categories, this is a
bit messy, so checkboxes are provided to be able to select whichever categories
are of interest.

# TODO

* more redmine graphs
* github
* discourse
* automate data collection
  * Redmine could parse the data locally using the R script, and put the csv in /public/ ...

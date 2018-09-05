# Foreman Community Stats

This is a ShinyR webapp for displaying data on the Foreman community.

The latest deployment can be found [here](http://140.211.167.4:3838/gregsutcliffe)

# Deployment

Follow the [RStudio Shiny Install Guide](http://docs.rstudio.com/shiny-server/#installation)

Once Shiny is up, copy this repo to the appropriate webapp dir (e.g. /srv/shiny-server/foreman)

## Development setup

Install [RStudio](https://www.rstudio.com) and then clone this repo. Open
`UI.R` and `server.R`, and RStudio should be able to run the webapp locally.

# Graphs

The graphs are tabbed by category, and should contain descriptions of the data
they present (and the interpretation, where appropriate).

# Local data

Currently the app uses cached data from our other services. The `scripts` dir
contains the necessary scripts. These scripts require access to the Redmine DB,
via an SSH tunnel (or running on Redmine itself), and use `config.yml` for storing
credentials.

### get_issues_from_redmine

This needs to be run against the Redmine DB (either directly on redmine01, or
on an offline DB created from one of the backups). It will output
`/tmp/issues.csv` which can be copied to the stats box.

### get_recent_users

This needs to be run against the Redmine DB (either directly on redmine01, or
on an offline DB created from one of the backups). It will output
`/tmp/users.csv` which can be copied to the stats box.

# TODO

* more redmine graphs
* github
* discourse
* automate data collection
  * Redmine could parse the data locally using the R script, and put the csv in /public/ ...

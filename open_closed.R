
# Libs --------------------------------------------------------------------

library(plotly)
library(lubridate)
library(dplyr)
library(tidyr)

# Helpers -----------------------------------------------------------------

build_cumsum = function(input_project) {

  # Filter issues by project
  if (input_project == 'All') {
    issues = global_issues
  } else {
    issues = filter(global_issues, project == input_project)
  }

  # Build a time series to hold cumsum
  result <- data.frame(
    day=seq(
      from=date(min(issues$created_on)),
      to=date(max(issues$created_on)),
      by="1 day")
  )

  # Issues opened each day
  opened <- issues %>%
    transmute(created_on = date(created_on)) %>% #strip times, keep dates
    group_by(created_on) %>%
    count()

  result <- merge(result,opened,by.x="day",by.y='created_on',all.x=TRUE)
  result[is.na(result$n),"n"] <- 0

  # Issues closed each day
  closed <- issues %>%
    select(closed_on) %>%
    na.omit() %>%
    transmute(closed_on = date(closed_on)) %>%
    group_by(closed_on) %>%
    count()
  result <- merge(result,closed,by.x="day",by.y='closed_on',all.x=TRUE)
  result[is.na(result$n.y),"n.y"] <- 0

  result <- result %>%
    mutate(net = n.x-n.y) %>%
    transmute(day = day, opened = cumsum(n.x), closed = cumsum(n.y), net.open = cumsum(net)) %>%
    gather(state, count, -day)
  result
}


# OnSource (static info) ------------------------------------------------

global_issues = read.csv('/tmp/issues.csv', stringsAsFactors = F)
global_cumsum = build_cumsum('All')
global_projects = c('All',distinct(global_issues,project))

# UI Elements -------------------------------------------------------------

OpenClosedTab = tabPanel("Open/Closed",
                         sidebarLayout(
                           mainPanel(
                             plotlyOutput('open_closed_graph')
                           ),
                           sidebarPanel(
                             wellPanel(
                               selectInput("open_closed_project", "Project:",
                                           global_projects,"All"),
                               dateRangeInput("open_closed_interval", "Date range:",
                                              start = now() - years(3),
                                              end   = now(),
                                              startview = 'year'
                               )
                             ),
                             tableOutput('open_closed_table'),
                             p('Select a region of the plot (or a new project) to update this table'),
                             p('TODO - Filter by category (or use a table?')
                           )
                         )
)

# Server Elements ---------------------------------------------------------

OpenClosedGraph <- function(interval,project) {
  cumsum = build_cumsum(project)
  subset = filter(cumsum, day %within% (interval[1] %--% interval[2]))
  p<-ggplot(subset,aes(x = day, y = count, colour = state)) +
    geom_line() +
    theme_gray() +
    xlab('Date') + ylab('Number of bugs') + ggtitle('Cumulative Open/Closed bugs over time')
  ggplotly(p) %>% layout(legend = list(traceorder='reversed',orientation='h'))
}

OpenClosedTable <- function(interval,project) {
  cumsum = build_cumsum(project)
  subset = filter(cumsum, day %within% (interval[1] %--% interval[2]))

  models <- subset %>%
    group_by(state) %>%
    dplyr::do(model = lm(count ~ day, data = .)) %>%
    mutate(coef = model$coef[2])

  table <- subset %>%
    group_by(state) %>%
    mutate(max = dplyr::last(count)) %>%
    group_by(state,max) %>%
    summarise() %>%
    bind_cols(coef = models$coef) %>%
    mutate(max = as.integer(max)) %>%
    rename(State = state,Total=max,`Rate of Increase`=coef)
}

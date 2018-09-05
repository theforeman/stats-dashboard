
# Libs --------------------------------------------------------------------

library(plotly)
library(lubridate)
library(dplyr)
library(tidyr)

# UI Elements -------------------------------------------------------------

OpenClosedTab = tabPanel("Open/Closed",
                         plotlyOutput('open_closed'),
                         tableOutput('open_closed_table'),
                         p('Open & Closed bugs over all time. WIP!'),
                         p('TODO - select & refit models by drag-select'),
                         p('TODO - Filter by project / category')
         )

# Server Elements ---------------------------------------------------------

OpenClosedServer <- function(output,issues) {
  cumsum = build_cumsum(issues)
  dates = min(issues$created_on) %--% max(issues$updated_on)
  subset = cumsum %>% filter(day %within% dates)
  output$open_closed <- renderPlotly({
    OpenClosedGraph(subset)
  })
  output$open_closed_table <- renderTable({
    OpenClosedTable(subset)
  },bordered = T)
}
OpenClosedGraph <- function(data) {
  p<-ggplot(data,aes(x = day,y=count,colour = state)) +
    geom_line() +
    theme_gray() +
    xlab('Date') + ylab('Number of bugs') + ggtitle('Open/Closed bugs per day')
  ggplotly(p) %>% layout(legend = list(traceorder='reversed',orientation='h'))
}
OpenClosedTable <- function(data) {
  models <- data %>%
    group_by(state) %>%
    dplyr::do(model = lm(count ~ day, data = .)) %>%
    mutate(coef = model$coef[2])
  table <- data %>%
    group_by(state) %>%
    mutate(max=max(count)) %>%
    group_by(state,max) %>%
    summarise() %>%
    bind_cols(coef = models$coef) %>%
    rename(State = state,Total=max,`Rate of Increase`=coef)
}

# Helpers -----------------------------------------------------------------

build_cumsum = function(issues) {

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
    transmute(day=day,opened=cumsum(n.x),closed=cumsum(n.y)) %>%
    gather(state, count, -day)

  result
}

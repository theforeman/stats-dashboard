#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(magrittr)
library(ggplot2)
library(lubridate)
library(plotly)

users <- read.csv('/tmp/users.csv', stringsAsFactors = F, colClasses = c('numeric','Date'))

issues <- read.csv('/tmp/issues.csv', stringsAsFactors = F)
projs <- issues %>% select(project,project_id) %>% unique() %>% arrange(project)
cats <- sort(unique(issues %>%
                      filter(project == 'Foreman', is_open == T) %>%
                      use_series(category)))
base_url <- 'https://projects.theforeman.org/issues?utf8=%E2%9C%93&set_filter=1&sort=id%3Adesc&f[]=status_id&op[status_id]=o&f[]=project_id&op[project_id]=%3D&f[]=&c[]=project&c[]=tracker&c[]=status&c[]=subject&c[]=assigned_to&c[]=updated_on&c[]=category&c[]=fixed_version&c[]=cf_5&group_by=cf_5&t[]=&v[project_id][]='

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {

  # Open/Closed

  # Rebuild LM table on graph zoom
  observe({
    proj = input$open_closed_project     # project picker
    d    = event_data("plotly_relayout") # get new viewport, returns integer:days
    if (is.null(d)) {
      interval = c(min(issues$created_on),max(issues$updated_on))
    } else {
      min = date('1970-01-01') + days(as.integer(d[1][1]))
      max = date('1970-01-01') + days(as.integer(d[2][1]))
      interval = c(min,max)
    }
    output$open_closed_table <- renderTable({OpenClosedTable(interval,proj)},bordered = T)
  })
  observe({
    proj     = input$open_closed_project
    interval = input$open_closed_interval
    output$open_closed_table <- renderTable({OpenClosedTable(interval,proj)},bordered = T)
  })
  output$open_closed_graph <- renderPlotly({
    OpenClosedGraph(input$open_closed_interval,input$open_closed_project)
  })

  # Categories

  updateSelectInput(session,"project",'Project',projs$project, 'Foreman')

  updateCheckboxGroupInput(session, "cats",
                           choices = cats,
                           selected = cats)

  observe({
    cats <- sort(unique(issues %>%
                          filter(project == input$project, is_open == T) %>%
                          use_series(category)))

    updateCheckboxGroupInput(session, "cats", choices = cats, selected = cats)
  })

  observe({
    cats <- sort(unique(issues %>%
                          filter(project == input$project, is_open == T) %>%
                          use_series(category)))

    x <- input$all_none
    # Can use character(0) to remove all choices
    if (is.null(x))
      x <- 'blank'

    if (x == 'All') {
      updateCheckboxGroupInput(session, "cats", selected = cats)
      updateCheckboxGroupInput(session, "all_none", selected = character(0))
    }
    if (x == 'None') {
      updateCheckboxGroupInput(session, "cats", selected = character(0))
      updateCheckboxGroupInput(session, "all_none", selected = character(0))
    }

  })

  output$project <- renderUI({
    h3(paste('Open Issues by Category & Triage: ',input$project))
  })
  output$header <- renderUI({
    a(
      h4(
        'Open in Redmine',
        class = "btn btn-default action-button",
        style = "fontweight:600"
      ),
      target = "_blank",
      href = (paste0(base_url, projs[projs$project==input$project,]$project_id))
    )
  })

  output$categories <- renderPlot({

    issues %>%
      filter(project == input$project, is_open == T) %>%
      filter(category %in% input$cats) %>%
      group_by(category) %>%
      ggplot(aes(x=category,fill=triaged)) +
      geom_bar(position = 'stack') +
      theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
      theme(axis.title.x = element_blank()) +
      ylab('Open Issues') +
      scale_fill_discrete(name = element_blank(),labels = c('Untriaged','Triaged'))
    })

  # Demographics
  output$users <- renderPlotly({
    plot_ly(data = users, x = users$created_on, type = 'histogram') %>%
      layout(title = "'Age' of recent Redmine users (last 6 months)",
             xaxis = list(title = "Time"),
             yaxis = list (title = "Count"))

  })
  output$users_box <- renderPlotly({
    plot_ly(data = users, x = users$created_on, type = 'box') %>%
      layout(title = "'Age' of recent Redmine users (last 6 months)",
             xaxis = list(title = "Time"),
             yaxis = list (title = ""))
  })
})

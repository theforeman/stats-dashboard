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

issues <- read.csv('/tmp/issues.csv')
cats <- sort(unique(issues %>% filter(project == 'Foreman',is_open == T) %>% use_series(category)))

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  updateCheckboxGroupInput(session, "cats",
                           choices = cats,
                           selected = c('API','Compute resources - VMware','Facts','Web Interface'))

  observe({
    x <- input$all_none
    # Can use character(0) to remove all choices
    if (is.null(x))
      x <- 'blank'

    str(x)
    if (x == 'All') {
      updateCheckboxGroupInput(session, "cats", selected = cats)
      updateCheckboxGroupInput(session, "all_none", selected = character(0))
    }
    if (x == 'None') {
      updateCheckboxGroupInput(session, "cats", selected = character(0))
      updateCheckboxGroupInput(session, "all_none", selected = character(0))
    }

  })

  output$categories <- renderPlot({

    issues %>%
      filter(project == 'Foreman',is_open == T) %>%
      filter(category %in% input$cats) %>%
      group_by(category) %>%
      ggplot(aes(x=category,fill=triaged)) +
      geom_bar(position = 'stack') +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      theme(axis.title.x = element_blank()) +
      ylab('Open Issues') +
      scale_fill_discrete(name = element_blank(),labels = c('Untriaged','Triaged')) +
      ggtitle('Open Issues by Category and Triage')
  })

})

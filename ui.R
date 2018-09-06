# Foreman Stats Shiny App
#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.

library(shiny)
library(plotly)

source('open_closed.R')

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel('Foreman Community Stats'),
  headerPanel(h4(paste("Last Updated:",file.info('/tmp/issues.csv')$ctime),
                 style = "text-decoration: underline")),

  tabsetPanel(
    OpenClosedTab,
    tabPanel("Category Issues",
      sidebarLayout(
        sidebarPanel(
          selectInput("project", "Project:",
            c("Foreman"),c("Foreman")),
          checkboxGroupInput('all_none','Select All/None',c('All','None')),
          checkboxGroupInput('cats', 'Categories')
        ),

        mainPanel(
          uiOutput('project'),
          uiOutput('header'),
          plotOutput("categories"),
          p('Shows the number of open bugs per category for the selected project.
            The proportion of bugs flagged as "Triaged" is shown in colour.'),
          p('Use the slect box on the left to pick a new project, or the checkboxes
            to limit which categories are shown.')
        )
      )
    ),
    tabPanel("Users",
      plotlyOutput('users'),
      p('Shows the "age" of accounts which have interacted with Redmine in the last 6 months.'),
      p('Here, "interacted" means logged/changed a ticket, or added a text comment'),
      hr(),
      plotlyOutput('users_box'),
      p('Same data as a box-plot, where it`s easier to see median and range information')
    )
  )

))

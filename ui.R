#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("Foreman Community Stats"),

  tabsetPanel(
    tabPanel("Category Issues",
      sidebarLayout(
        sidebarPanel(
          h5(paste('Last Updated:',file.info('/tmp/issues.csv')$ctime),
            style = "text-decoration: underline"),
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
    tabPanel("Open/Closed",
      plotlyOutput('open_closed'),
      p('Open & Closed bugs over all time. TODO - filter by project / category :)')
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

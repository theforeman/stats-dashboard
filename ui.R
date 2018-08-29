#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("Foreman Redmine"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      selectInput("project", "Project:",
                  c("Foreman"),c("Foreman")),
      checkboxGroupInput('all_none','Select All/None',c('All','None')),
      checkboxGroupInput('cats', 'Categories')
    ),

    # Show a plot of the generated distribution
    mainPanel(
       plotOutput("categories"),
       tableOutput('data')
    )
  )
))

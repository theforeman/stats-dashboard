# Foreman Stats Shiny App
#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.

library(shiny)
library(DT)
library(plotly)
library(crosstalk)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  h1("Time to Merge, by repo, date & # of PRs", align = "center"),
  plotlyOutput("x2"),
  DT::dataTableOutput("x1"),
  fluidRow(
    p(class = 'text-center', downloadButton('x3', 'Download Filtered Data'))
  )
))

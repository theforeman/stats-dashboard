#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
library(plotly)
library(crosstalk)

shinyUI(fluidPage(
  h1("Plugin downloads (unique IPs per day) over time", align = "center"),
  h3('Shows the ranked top 20 plugins over the last two weeks'),
  h3('Click a plugin to see it`s daily downloads'),
  plotlyOutput("x2"),
  h4('Please excercise caution, this data is derived from the httpd download logs, and thus heavily biased'),
  DT::dataTableOutput("x1"),
  fluidRow(
    p(class = 'text-center', downloadButton('x3', 'Download Filtered Data'))
  )
))

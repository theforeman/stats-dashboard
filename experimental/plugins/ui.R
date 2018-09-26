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
  h1("Plugin downloads over time", align = "center"),
  plotlyOutput("x2"),
  DT::dataTableOutput("x1"),
  fluidRow(
    p(class = 'text-center', downloadButton('x3', 'Download Filtered Data'))
  )
))

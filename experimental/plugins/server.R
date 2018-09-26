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
library(dplyr)

if (!exists('data2')) {
  data2   = as_tibble(read.csv('/tmp/plugins.csv',stringsAsFactors = F))
  # source('./log_parser.R')
}

by_day <- data2
total  <- data2 %>% group_by(Package) %>% summarise(n=round(sum(n),0)) %>% arrange(desc(n))

shinyServer(function(input, output, session) {

  d <- SharedData$new(total, ~Package)

  # highlight selected rows in the scatterplot
  output$x2 <- renderPlotly({

    s <- input$x1_rows_selected

    if (!length(s)) {
      p <- total %>%
        group_by(Package) %>%
        summarise(n=sum(n)) %>%
        arrange(desc(n)) %>%
        head(20) %>%
        ggplot(aes(x=Package,y=n,fill=Package)) +
        geom_bar(stat='identity') +
        theme(axis.text.x = element_text(angle = 90)) +
        ylab('Sum of Unique IPs/day')


      ggplotly(p) %>%
        layout(showlegend = F)

    } else if (length(s)) {
      packages = total[s,1]
      data <- by_day %>% filter(Package %in% packages$Package)

      pp <- data %>%
        ggplot(aes(x=Date,y=n,group=Package,color=Package)) +
        geom_point() +
        ylab('Unique IPs/day')

      if (length(s) == 1) {
        pp = pp + geom_smooth(method='lm')
      } else {
        pp = pp + geom_smooth(method='lm', se = F)
      }

      ggplotly(pp) %>%
        layout(showlegend = F)

    }

  })

  # highlight selected rows in the table
  output$x1 <- DT::renderDataTable({
    m2 <- total[d$selection(),]
    dt <- DT::datatable(total)
    if (NROW(m2) == 0) {
      dt
    } else {
      DT::formatStyle(dt, "Package", target = "row",
                      color = DT::styleEqual(m2$name, rep("white", length(m2$name))),
                      backgroundColor = DT::styleEqual(m2$name, rep("black", length(m2$name))))
    }
  })

  # download the filtered data
  output$x3 = downloadHandler('plugins-filtered.csv', content = function(file) {
    s <- input$x1_rows_selected
    if (length(s)) {
      packages = total[s,1]
      data <- by_day %>% filter(Package %in% packages$Package)

      write.csv(data, file)
    } else if (!length(s)) {
      write.csv(by_day, file)
    }
  })

})


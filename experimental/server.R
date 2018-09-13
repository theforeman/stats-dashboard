#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
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
library(magrittr)
library(ggplot2)
library(lubridate)

# Get this properly imported
ttm_raw   = as.tibble(read.csv('/tmp/time_to_merge.csv',stringsAsFactors = F)) %>%
  mutate(mergedAt = ymd_hms(mergedAt))
ttm_month = ttm_raw %>%
  mutate(month = month(mergedAt),
         year  = year(mergedAt),
         date  = ymd(paste0(year,'-',month,'-01'))) %>%
  group_by(name,date) %>%
  summarise(n=n(),ttm=mean(ttm))
ttm_total = ttm_month %>%
  group_by(name) %>%
  summarise(n=sum(n),ttm=mean(ttm))

shinyServer(function(input, output, session) {
  d <- SharedData$new(ttm_total, ~name)

  # highlight selected rows in the scatterplot
  output$x2 <- renderPlotly({

    s <- input$x1_rows_selected

    if (!length(s)) {
      p <- ttm_month %>%
        plot_ly(x = ~date, y = ~ttm, mode = "markers", color = I('black')) %>%
        layout(showlegend = F)
    } else if (length(s)) {
      label = ttm_total[s,1]
      data <- ttm_raw %>% filter(name %in% label$name)
      p <-ggplot(data,aes(x=mergedAt,y=ttm, label=number)) + geom_point() + geom_smooth()
      ggplotly(p)
    }

  })

  # highlight selected rows in the table
  output$x1 <- DT::renderDataTable({
    m2 <- ttm_total[d$selection(),]
    dt <- DT::datatable(ttm_total)
    if (NROW(m2) == 0) {
      dt
    } else {
      DT::formatStyle(dt, "rowname", target = "row",
                      color = DT::styleEqual(m2$name, rep("white", length(m2$name))),
                      backgroundColor = DT::styleEqual(m2$name, rep("black", length(m2$name))))
    }
  })

  # download the filtered data
  output$x3 = downloadHandler('mtcars-filtered.csv', content = function(file) {
    s <- input$x1_rows_selected
    if (length(s)) {
      write.csv(m[s, , drop = FALSE], file)
    } else if (!length(s)) {
      write.csv(m[d$selection(),], file)
    }
  })
})

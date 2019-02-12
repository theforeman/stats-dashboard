#' ---
#' title: "Rackspace Costs, year-to-date"
#' author: "Greg SUtcliffe"
#' date: "2018-08-16"
#' ---

#+ setup, include=FALSE
library(ggplot2)
library(knitr)
setwd('~/Nextcloud/Work/Data/Rackspace')
source('./rackspace-calc.R')
costs <- rackspace('./original-csv-files')

#' This graph covers the cost breakdown of the previous month's costs. Billing is on 
#' the 7th of the month, so e.g. the July entry will cover June 8th -> July 7th

#+ report, include=TRUE
plot1 <- ggplot(costs,aes(x=BILL_END_DATE,y=as.numeric(sum),
                          fill=fct_relevel(EVENT_TYPE,c('Other',
                                                        'NG Server Uptime',
                                                        'NG Server Bandwidth Out',
                                                        'CBS Volume')))) +
  geom_bar(stat='identity',position='stack') +
  labs(x="Date",y="Cost (US dollars)",title="Rackspace Budget, monthly") +
  scale_fill_discrete(name='Cost Type') +
  geom_hline(yintercept = 2000)
print(plot1)

#' The breakdown of the most recent costs is as follows:
costs %>% filter(BILL_END_DATE > (now() - months(1))) %>% kable()

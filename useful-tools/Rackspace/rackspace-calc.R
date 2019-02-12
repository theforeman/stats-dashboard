rackspace <- function(csvdir) {
  library(dplyr)
  library(lubridate)
  library(forcats)
  
    # Load CSVs
    setwd(csvdir)
    files = dir('./',pattern = '*.csv')
    raw_bills = lapply(files, read.csv) %>% bind_rows()

    # Filter on charges only
    costs <- raw_bills %>%
      filter(IMPACT_TYPE == "CHARGE") %>%
      select("EVENT_TYPE","RES_NAME","AMOUNT","BILL_END_DATE") %>%
      mutate(BILL_END_DATE = mdy_hm(as.character(BILL_END_DATE)))

    # Keep the top entries by cost
    # Manual for now
    costs <- costs %>% 
      mutate(EVENT_TYPE = fct_collapse(EVENT_TYPE,
        Other = c('CBS Storage','Server Image','Files Bandwidth Out','NG Server IP - Hours')
        ))
    # Print total spend
    costs %>%
      group_by(EVENT_TYPE,BILL_END_DATE) %>%
      summarise(sum=sum(AMOUNT)) %>%
      arrange(desc(BILL_END_DATE),desc(sum))

}

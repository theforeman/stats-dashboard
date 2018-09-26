setwd('~/Nextcloud/Work/Data/RSS/package_logs/')
#library(dplyr)
library(tidyverse)
library(lubridate)
#library(forcats)
library(digest)
library(ggplot2)
library(plotly)

# DATA EXTRACT
# This data comes from the web02 httpd logs, which is pre-processed into a 
# holding dir. It can be fetched like:
#   scp gregsutcliffe@theforeman.org:/var/cache/parsed_apache_logs/\* .
#   
# RSS data comes from the web02 httpd logs. You can get it like this:
#   zgrep "/feed.xml" /var/log/httpd/*web*log* > /tmp/rss.httpd.log 
# 
# You also need to strip escaped quotes as it breaks read.csv separator detection
#   sed 's/\\\"//g' /tmp/rss.httpd.log > ./rss.httpd.log     
#
# There are also double slashes, clean them with
#   sed -i 's/\/\//\//g' *.log
#   
# Check it with head, wc, etc.

vdigest <- Vectorize(digest)

parse_pkg <- function(package_string) {
  s = package_string
  s = str_extract(s," .* ") # get the centre portion, space delimted
  s = str_trim(s)
  s = str_split(s,'/')
  s = lapply(s, tail, n = 1L)
  # try to turn letter/number connections into underscores
  # e.g. openscap-2.0.1 should be openscap_2.0.1
  s = str_replace_all(s,'(?<=[[:alpha:]])-(?=[[:digit:]])','_')
  # try to make letter/letter connections into dashes
  # e.g. default_hostgroup should be default-hostgroup
  s = str_replace_all(s,'(?<=[[:alpha:]])_(?=[[:alpha:]])','-')
  s
}

cleanup <- function(raw) {
  raw %>%
    separate(V1, c('V1','IP'), ':', extra='merge') %>%
    mutate(
      IP = vdigest(IP,algo='sha1'),
      Date = date(dmy_hms(V4)),
      Package.raw = parse_pkg(V6)
    ) %>%
    # RPMs are a mess....
    mutate(Package.raw = str_replace(Package.raw,'^ruby193-rubygem-foreman(-|_)','')) %>%
    mutate(Package.raw = str_replace(Package.raw,'^rubygem-foreman(-|_)','')) %>%
    mutate(Package.raw = str_replace(Package.raw,'^tfm-rubygem-foreman(-|_)', '')) %>%
    # DEBs are better....
    mutate(Package.raw = str_replace(Package.raw,'^ruby-foreman(-|_)', '')) %>%
    separate(Package.raw, c("Package", "Version"), sep = "_",extra='drop',remove=F) %>%
    separate(Version,'Version',sep = '-',extra='drop') %>%
    select(IP,Date,Package.raw,Package,Version) %>%
    arrange(Date)
}

files <- list.files('.','*')
data.list <- lapply(files, read.csv, header = F, sep = " ", stringsAsFactors = F)
data.cat <- do.call(rbind, data.list) %>% dplyr::distinct()

logs.tmp <- cleanup(data.cat) %>% distinct()

# Filter out known-pointless stuff
regex = paste(sep = "|",
              "^foreman$",
              "^foreman-(api|console|devel|test|debug|assets)$",
              "^foreman-(cli|compute|proxy|installer|plugin)$",
              "^foreman-(journald|postgresql|mysql2|sqlite)$",
              "^(centos|foreman)-release",
              "-core",
              "apipie",
              "bastion",
              "bundler",
              "doc",
              "deface",
              "dynflow",
              "hammer",
              "http-parser",
              "ipmi",
              "kafo",
              "mod.passenger",
              "nodejs",
              "parse-cron",
              "puppet",
              "rhscl-ruby193-epel",
              "rhscl-v8314-epel",
              "rkerberos",
              "rsec",
              "ruby193-facter",
              "ruby193-ruby-wrapper",
              "ruby-awesome-print",
              "ruby-clamp",
              "ruby(gem)?-fast-gettext",
              "ruby-libvirt",
              "ruby-powerbar",
              "ruby-unicode",
              "selinux",
              "scap-client",
              "smart.proxy",
              "tasks",
              "tfm-rubygem-angular",
              "tfm-rubygem-rainbow",
              "tfm-rubygem-wicked"
              )

logs <- logs.tmp %>%
  filter(!(str_detect(Package,regex)))

data = logs %>%
  # Where a user downloads multiple versions on the same day, take the average
  group_by(IP,Date,Package,Version) %>% count() %>%
  group_by(IP,Date,Package) %>% summarise(n=median(n)) %>%
  # Then total up all the unique sets of downloads for a given day
  group_by(Date,Package) %>% summarise(n=sum(n)) %>%
  arrange(Date,desc(n))
  
data2 <- data %>%
  group_by(Date) %>%
  filter(row_number() <= 20) %>%
  filter(Date > min(data$Date)) %>%
  filter(Date < max(data$Date)) # first and last are incomplete data


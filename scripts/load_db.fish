#!/usr/bin/fish

# RBenv
status --is-interactive; and source (rbenv init -|psub)

cd ~/git/redmine

scp root@redmine01.theforeman.org:/var/lib/redmine/redmine.backup.sql.gz ./
gunzip ./redmine.backup.sql.gz
sed -i 's/adminpz8bn8d/greg/g' ./redmine.backup.sql

bundle exec rake db:drop db:create
psql -d redminedev -f ./redmine.backup.sql

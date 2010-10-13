# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :cron_log, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
every 2.hours, :at => 30 do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'FeedEntry.perform' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

# every 30.minutes do
  # runner "ScraperRunner.new(:limit => 5, :email_results => true).refresh_stale"
  # command "cd ~/sites/twfy_local/current && RAILS_ENV=production LIMIT=2 EMAIL_RESULTS=true /opt/ruby-enterprise-1.8.6/bin/rake run_stale_scrapers >> log/cron_log 2>&1"
# end

every 3.hours do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'Scraper.unproblematic.stale.find(:all, :limit => 30).each{|scraper| Delayed::Job.enqueue scraper} if Delayed::Job.count == 0' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

# every 7.days do
#   runner "Dataset.stale.each(&:process)"
# end

every :sunday, :at => '3am' do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'Service.refresh_all_urls' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

every :monday, :at => '3am' do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'PoliceForce.all.each { |force| force.update_teams }' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

every :monday, :at => '4am' do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'PoliceTeam.all.each { |team| team.update_officers }' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

every :wednesday, :at => '4am' do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'Council.update_social_networking_info' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

every 1.day, :at => '5am' do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'Charity.add_new_charities' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

every 1.day, :at => '2am' do
  command "/opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/runner -e production 'WdtkRequest.process' >> /home/cculture/sites/twfy_local/current/log/cron_log 2>&1"
end

# every :sunday, :at => '1am' do
#   command "RAILS_ENV=production /opt/ruby-enterprise-1.8/bin/ruby /home/cculture/sites/twfy_local/current/script/rake import_council_officers"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

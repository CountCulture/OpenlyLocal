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
every 1.hours do
  command "rm -rf ~/sites/twfy_local/shared/cache/views"
end
every 30.minutes do
  # runner "ScraperRunner.new(:limit => 5, :email_results => true).refresh_stale"
  command "cd ~/sites/twfy_local/current && RAILS_ENV=production LIMIT=2 EMAIL_RESULTS=true rake run_stale_scrapers"
end
every 7.days do
  runner "Dataset.stale.each(&:process)"
end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

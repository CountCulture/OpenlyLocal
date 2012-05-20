desc 'Update FeedEntries if not already running'
task :update_feed_entries => :environment do
  if already_running_process("update_feed_entries")
    puts "Already updating FeedEntries. No need to start"
  else
    puts "Starting updating FeedEntries"
    FeedEntry.perform
  end
end

# TODO: Will always return true if task is run with Rake.
def already_running_process(process_string)
  cmd = %Q[ps alx | grep #{process_string} | grep -v grep | grep -v '/bin/bash'] # l instead of u gives long output
  puts "Checking to see if running #{process_string} : #{cmd}"
  pids = `#{cmd}`.split("\n").collect{ |line| line.split[2] } #NB should be [1] on mac, but ps aux seems to be different on Debian
  pids.delete($$.to_s)
  !pids.empty?
end
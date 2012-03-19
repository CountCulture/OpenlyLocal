require 'resque/tasks'
task "resque:setup" => :environment do
  # generic worker setup, e.g. Hoptoad for failed jobs
end

namespace :resque do 
  desc 'start all background resque daemons' 
  task :start_daemons do 
    # mrake_start "resque_scheduler resque:scheduler" 
    workers_config.each do |worker, config| 
      task_details = "resque_#{worker} resque:work QUEUE=#{config['queues']} #{config['cl_params']}"
      mrake_start task_details
    end 
  end 
  
  desc 'stop all background resque daemons' 
  task :stop_daemons do 
    sh "./script/monit_rake stop resque_scheduler" 
    workers_config.each do |worker, config| 
      sh "./script/monit_rake stop resque_#{worker} -s QUIT" 
    end
    puts "Stopped all background resque daemons. Now clearing all restricted_performer locks..."
    Rake::Task["resque:clear_performer_locks"].invoke
    puts "Done."
  end 
  
  desc 'clear all restricted_performer locks' 
  task :clear_performer_locks => :environment do 
    Resque.redis.keys.select{ |k| k.match /performer_lock/ }.each{ |k| Resque.redis.del(k) }
  end
  
  desc 'move queued items to new queue'
  task :move_queued_items => :environment do
    i = 0
    unless source_queue = ENV['QUEUE_NAME']
      puts "FROM which queue do you want to move items [after_create]"
      response = $stdin.gets.chomp
      source_queue = response.blank? ? :after_create : response.to_sym
    end
    unless dest_queue = ENV['DEST_QUEUE']
      puts "TO which queue do you want to move items [low]"
      response = $stdin.gets.chomp
      dest_queue = response.blank? ? :low : response.to_sym
    end
    unless quantity = ENV['QUANTITY']
      puts "How many items do you want to move [all]"
      response = $stdin.gets.chomp
      quantity = response.blank? ? :all : response.to_i
    end
    puts "About to move #{quantity} items from #{source_queue} queue to #{dest_queue} queue"
    while obj = Resque.pop(source_queue)
      Resque.push(dest_queue, obj)
      i+=1
      break if quantity.is_a?(Fixnum) and i >= quantity
      print '.'
    end
    puts "Successfully moved #{i} items from #{source_queue} queue to #{dest_queue} queue"
  end
  
  desc 'move items to back of queue'
  task :move_to_back_of_queue => :environment do
    unless source_queue = ENV['QUEUE_NAME']
      puts "From which queue do you want to move items to back [low]"
      response = $stdin.gets.chomp
      source_queue = response.blank? ? :low : response.to_sym
    end
    unless quantity = ENV['QUANTITY']
      puts "How many items do you want to move to back of queue [5]"
      response = $stdin.gets.chomp
      quantity = response.blank? ? 5 : response.to_i
    end
    quantity.times do
      obj = Resque.pop(source_queue)
      Resque.push(source_queue, obj)
    end
    puts "Successfully moved #{quantity} items from #{source_queue} queue to back"
  end
  
  desc 'truncate queue' 
  task :truncate_queue => :environment do 
    unless source_queue = ENV['QUEUE_NAME']
      puts "From which queue do you want to move items to back [low]"
      response = $stdin.gets.chomp
      source_queue = response.blank? ? :low : response.to_sym
    end
    unless quantity = ENV['SIZE']
      puts "How many items do you reduce queue to [100,000]"
      response = $stdin.gets.chomp
      new_size = response.blank? ? 100000 : response.to_i
    end
    Resque.redis.ltrim("queue:#{source_queue}", 0, new_size-1)
  end
  
  desc 'unregister all workers' 
  task :unregister_workers => :environment do 
    Resque.workers.each(&:unregister_worker)
  end
  
  def self.workers_config 
    YAML.load(File.open(ENV['WORKER_YML'] || 'config/resque_workers.yml')) 
  end 
  
  def self.mrake_start(task_details) 
    sh "nohup ./script/monit_rake start #{task_details} RAILS_ENV=#{ENV['RAILS_ENV']} >> log/daemons.log &" 
  end 
end
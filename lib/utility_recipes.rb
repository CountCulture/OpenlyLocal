# the aptitude recipes are based on Capistrano Bells (http://svn.nakadev.com/open/plugins/bells)
namespace :aptitude do
  
  desc "Runs aptitude update on remote server"
  task :update do
    logger.info "Running aptitude update"
    sudo "aptitude update"
  end
  
  desc "Runs aptitude upgrade on remote server"
  task :upgrade do
    sudo "aptitude upgrade" do |channel, stream, data|
      puts "#{channel[:host]}: #{data}"
      channel.send_data(input = $stdin.gets) if data =~ /Do you want to continue/
    end
  end
  
  desc "Search for aptitude packages on remote server"
  task :search do
    puts "Enter your search term:"
    deb_pkg_term = $stdin.gets.chomp
    update      
    stream "aptitude search #{deb_pkg_term}"
  end
  
  desc "Installs a package using the aptitude command on the remote server."
  task :install do
    puts "What is the name of the package(s) you wish to install?"
    deb_pkg_name = $stdin.gets.chomp
    raise "Please specify deb_pkg_name" if deb_pkg_name == ''
    update
    logger.info "Installing #{deb_pkg_name}..."
    sudo "aptitude install #{deb_pkg_name}", /^Do you want to continue\?/
  end
end

# the gems recipes come from Capistrano Bells (http://svn.nakadev.com/open/plugins/bells)
namespace :gems do
  
  task :default do
    desc <<-DESC
      
      Tasks to adminster Ruby Gems on a remote server: \
       \
      cap gems:list \
      cap gems:update \
      cap gems:install \
      cap gems:remove \
      
    DESC
    puts desc
  end
  
  desc "List gems on remote server"
  task :list, :roles => [:app, :sphinx] do
    stream "gem list"
  end
  
  desc "Update gems on remote server"
  task :update, :roles => [:app, :sphinx] do
    puts "Enter the name of the gem you'd like to update:"
    gem_name = $stdin.gets.chomp
    logger.info "trying to update #{gem_name}"
    sudo "gem update #{gem_name}"
  end
  
  desc "Install a gem on the remote server"
  task :install, :roles => [:app, :sphinx] do
    # TODO Figure out how to use Highline with this
    puts "Enter the name of the gem you'd like to install:"
    gem_name = $stdin.gets.chomp
    logger.info "trying to install #{gem_name}"
    sudo "gem install -y #{gem_name}"
  end
  
  desc "Uninstall a gem from the remote server"
  task :remove, :roles => [:app, :sphinx] do
    puts "Enter the name of the gem you'd like to remove:"
    gem_name = $stdin.gets.chomp
    logger.info "trying to remove #{gem_name}"
    sudo "gem uninstall #{gem_name}"
  end
  
end

task :install_syslog_gems, :roles => :app do
  sudo 'gem install -y production_log_analyzer'
end

task :install_syslog_filter, :roles => :app do
  sudo %{echo "!#{application} *.* #{shared_path}/log/#{stage}.log" >> /etc/syslog.conf}
  sudo "/etc/init.d/sysklogd restart" # works for Ubuntu
end

task :install_log_rotate_script, :roles => :app do
  rotate_script = %Q{#{shared_path}/log/#{stage}.log {
      rotate 7                                                                                           
      compress                                                                                           
      daily                                                                                              
      missingok                                                                                          
      notifempty                                                                                         
      postrotate                                                                                         
      /etc/init.d/mongrel_cluster restart --clean                                                        
      endscript                                                                                          
      sharedscripts                                                                                      
      mail webmaster@pushrodmedia.co.uk                                                                  
      mailfirst                                                                                          
}}
  put rotate_script, "#{shared_path}/logrotate_script"
  sudo "cp #{shared_path}/logrotate_script /etc/logrotate.d/#{application}"
  run "rm #{shared_path}/logrotate_script"
end

set :log_email_recipient, "webmaster@pushrodmedia.co.uk"

task :analyze_logs, :roles => :app do
  sudo %Q{chmod a+r #{shared_path}/log/*.gz}
  run %Q{for file in #{shared_path}/log/*.gz; \
         do gzip -dc "$file" | \
         pl_analyze /dev/stdin -e #{log_email_recipient}; \
         done}
end


require File.expand_path("../initializers/authentication_details", __FILE__)
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'delayed/recipes'

set :stages, %w(staging production testbed)

set :application, "twfy_local"
# set :repository,  "set your repository location here"
set :repository,  "git@github.com:CountCulture/OpenlyLocal.git"
# set :repository, "file://."

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/cculture/sites/#{application}"

set :default_environment, {
  'PATH' => "/opt/ruby-enterprise-1.8/bin/:$PATH"
}
# If you aren't using Subversion to manage your source code, specify
# your SCM below:
default_run_options[:pty] = true
set :scm, :git
set :scm_username, SCM_USERNAME 
set :scm_passphrase,  SCM_PASSPHRASE
# set :deploy_via, :remote_cache
set :deploy_via, :remote_cache
# set :git_shallow_clone, 1
set :branch, "master"
set :user, "cculture"
# set :copy_exclude, [".svn", ".git"]
ssh_options[:forward_agent] = true
ssh_options[:port] = 7012

set :delayed_jobs_args, "-n 3"
set :delayed_job_server_role, :backgrounder
# uncomment this next line to have bundler report on which gems it's installing
# set :bundle_flags,    "--deployment"

after "deploy:update_code", "deploy:update_symlinks"

after :deploy, 'sitemap:copy_sitemap'
# after "deploy:stop", "delayed_job:stop"
# after "deploy:start", "delayed_job:start"
# after "deploy:restart", "delayed_job:restart"
namespace :deploy do
  
  task :check_path, :roles => [:app, :backgrounder] do
    run "echo $PATH" # allows us to check if there's a prob with the path
  end
  
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{latest_release}/tmp/restart.txt"
  end

  desc "Uploads a new Nginx configuration file and reloads the config"
  task :update_nginx_config, :roles => :web do
    generate_nginx_config
    answer = Capistrano::CLI.ui.ask "Get ngnix to reload with new conf file [Y|n]?"
    reload_nginx_config if answer =~ /Y|Yes/
  end

  desc "Creates the Nginx config from a template and puts it in the proper location and then tests it"
  task :generate_nginx_config, :roles => :web do
    conf_file = File.read(File.join(File.dirname(__FILE__), "nginx_#{stage}.conf"))
    put(conf_file, "#{deploy_to}/tmp/new_nginx.conf") #upload new conf file
    sudo "mv /opt/nginx/conf/nginx.conf /opt/nginx/conf/nginx_BACKUP.conf" # backup old file
    sudo "mv #{deploy_to}/tmp/new_nginx.conf /opt/nginx/conf/nginx.conf" # move new one in it's place
    sudo "/opt/nginx/sbin/nginx -t -c /opt/nginx/conf/nginx.conf" # check new conf file is OK
  end

  desc "Tell Nginx to reload already loaded configuration file"
  task :reload_nginx_config, :roles => :web do
    sudo "kill -HUP `cat /opt/nginx/logs/nginx.pid`"
  end

  desc "Download current Nginx configuration file"
  task :get_current_nginx_config, :roles => :web do
    get "/opt/nginx/conf/nginx.conf", "current_nginx_#{stage}.conf"
  end

  desc "Full deployment including migrations"
  task :full, :roles => :app do
    transaction do
      web.disable
      update
      migrate_db
      restart
      web.enable
    end
  end

  desc "Migrate code from app_server_1."
  task :migrate_db, :roles => [:app] do
    run("cd #{current_path} && RAILS_ENV=#{stage} rake db:migrate")
  end

  desc "Flush the fragment/action cache store"
  task :flush_cache, :roles => :app do
    run("rm -rf #{shared_path}/cache/views")
  end
  
  desc "Uploads new copies of the config files from local machine"
  task :upload_conf_files, :roles => [:app, :backgrounder] do
    top.upload('./config/', "#{shared_path}", :via=> :scp, :recursive => true)
  end

  namespace :delayed_job do
    desc "Stop the delayed_job process"
    task :stop, :roles => :backgrounder do
      if stage == 'production'
        run "cd #{current_path}; RAILS_ENV=production bundle exec script/delayed_job stop"
        run "cd #{current_path}; bundle exec script/kill_delayed_job"
      end
    end

    desc "Start the delayed_job process"
    task :start, :roles => :backgrounder do
      if stage == 'production'
        run "cd #{current_path}; RAILS_ENV=production bundle exec script/delayed_job -n 2 start" # this is for other jusrisdictions
      end
    end
  end
  
  
  # custom disable_web task to use maintenance template
  namespace :web do
    desc <<-DESC
      Present (custom) maintenance page to visitors. Disables application's web \
      interface by writing a "maintenance.html" file to each web server. The \
      servers must be configured to detect the presence of this file, and if \
      it is present, always display it instead of performing the request.

      NB this task has been customized to present twfy-branded maintenance page
    DESC
    task :disable, :roles => :web, :except => { :no_release => true } do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }

      reason = ENV['REASON']
      deadline = ENV['UNTIL']

      template = File.read(File.join(File.dirname(__FILE__), "../app/views/layouts/maintenance.html.erb"))
      result = ERB.new(template).result(binding)

      put result, "#{shared_path}/system/maintenance.html", :mode => 0644
    end
  end

  desc "Update the crontab file"
  task :update_crontab, :roles => :backgrounder do
    run "cd #{release_path} && whenever --update-crontab #{application}"
  end
  
  desc "Creates sym links for shared folders" 
  task :update_symlinks, :roles => [:app, :backgrounder] do
    run <<-EOF
      cd #{release_path} && 
      ln -s #{shared_path}/config/initializers/authentication_details.rb #{release_path}/config/initializers/authentication_details.rb &&
      ln -s #{shared_path}/config/initializers/geokit_config.rb #{release_path}/config/initializers/geokit_config.rb &&
      ln -s #{shared_path}/config/initializers/hoptoad.rb #{release_path}/config/initializers/hoptoad.rb &&
      ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
      ln -s #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml &&
      ln -s #{shared_path}/config/resque.yml #{release_path}/config/resque.yml &&
      ln -s #{shared_path}/config/smtp_gmail.yml #{release_path}/config/smtp_gmail.yml &&
      ln -s #{shared_path}/config/twitter.yml #{release_path}/config/twitter.yml &&
      ln -s #{shared_path}/config/openlylocal.com.priv #{release_path}/config/openlylocal.com.priv &&
      ln -s #{shared_path}/cache #{release_path}/tmp/cache &&
      ln -s #{shared_path}/data #{release_path}/db/data &&
      mkdir #{release_path}/public/councils &&
      ln -s #{shared_path}/data/downloads/spending.csv.zip #{release_path}/public/councils/spending.csv.zip &&
      ln -s #{shared_path}/data/downloads/planning_applications.zip #{release_path}/public/councils/planning_applications.zip
    EOF
  end

end

desc "Runs stale scrapers" 
task :run_stale_scrapers, :roles => [:app] do
  run("cd #{current_path} && RAILS_ENV=#{stage} EMAIL_RESULTS=true rake run_stale_scrapers")
end

namespace :sitemap do
  desc "Copy the sitemap files after deploy"
  task :copy_sitemap, :roles => :app do
    puts "copy Rails sitemap files from old release to current one"
    # check if sitemap exists, and copy over if it does
    run "[ -f #{previous_release}/public/sitemap*.xml.gz ] && cp #{previous_release}/public/sitemap*.xml.gz #{current_release}/public/ || echo \"Sitemap does not exists\""
  end
  
  desc "refresh the sitemap"
  task :refresh, :roles => :app do
    puts "Refresh the xml Sitemap"
    run "cd #{current_path} && RAILS_ENV=#{stage} rake sitemap:refresh"
  end
  
end

namespace :resque do 
  desc "Stop the resque daemon" 
  task :stop, :roles => :backgrounder do 
    run "cd #{current_path} && RAILS_ENV=production rake resque:stop_daemons; true" 
  end 
  desc "Start the resque daemon" 
  task :start, :roles => :backgrounder do 
    run "cd #{current_path} && RAILS_ENV=production rake resque:start_daemons" 
  end 
end



# PRODUCTION-specific deployment configuration
# Put general deployment config in config/deploy.rb

role :app, 'liberia.openlylocal.com'
role :web, 'liberia.openlylocal.com'
role :db,  'kiribati.openlylocal.com', :primary => true, :no_release => true
#role :backgrounder, 'jersey.openlylocal.com'
role :backgrounder, 'nevis.openlylocal.com'

set :rails_env, 'production'

after 'deploy:symlink', 'deploy:update_crontab'

after "deploy:stop", "delayed_job:stop", "resque:stop"
after "deploy:start", "delayed_job:start", "resque:start"
after "deploy:restart", "delayed_job:stop", "resque:stop", "delayed_job:start", "resque:start"


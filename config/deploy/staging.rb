# STAGING-specific deployment configuration
# Put general deployment config in config/deploy.rb

# set :user, "frankg"
# set :deploy_to, "/home/frankg/sites/#{application}"
# set :rails_env, "staging"
# # set :branch, "master"
# 
# role :app, "austin.pushrod.com"
# role :web, "austin.pushrod.com"
# # role :db,  "cooper.pushrod.com", :primary => true, :no_release => true
# # role :app1, "bentley.pushrod.com"
# role :app1, "austin.pushrod.com"
# role :backgrounder, "austin.pushrod.com"
server "46.43.37.25", :web, :app, :backgrounder, :primary => true
set :branch, "head"

# desc "Creates sym links for shared folders" 
# task :update_symlinks, :roles => [:app, :web] do
#   run <<-EOF
#     cd #{release_path} && 
#     ln -s #{shared_path}/photo_images #{release_path}/public/photo_images &&
#     ln -s #{shared_path}/photos #{release_path}/public/photos
#   EOF
# end

# desc "Updates staging db and photos from production server" 
# task :sync_with_production, :roles => [:app] do
#   run "/home/frankg/s3sync/download.sh"
#   # run "/home/frankg/s3sync/download.sh && /home/frankg/s3sync/download_db.sh"
#   # run "gunzip < ~/sites/backups/carstuff_production_A.sql.tar.gz | mysql -u root -p#{PRODUCTION_MYSQL_PASSWORD} carstuff_production"
# end
# 
task :sync_with_production_db, :roles => [:app] do
  run <<-EOF
    /home/frankg/s3sync/download_db.sh && 
    gunzip < ~/sites/backups/twfy_local_production_A.sql.gz | mysql -u twfyl_user -p#{STAGING_MYSQL_PASSWORD} twfy_local_staging
  EOF
end

# Override standard sitemap so doesn't ping search engines
namespace :sitemap do
  desc "refresh the sitemap"
  task :refresh, :roles => :app do
    puts "Refresh the xml Sitemap"
    run "cd #{current_path} && RAILS_ENV=#{stage} rake sitemap:refresh:no_ping"
  end
end
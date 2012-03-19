require 'resque/server'
require 'resque/failure/airbrake'

Resque::Failure::Airbrake.configure do |config|
  config.api_key = '3f276ee6addc559ee3f05304075c7798'
  config.secure = true
end

rails_env = ENV['RAILS_ENV'] || 'development'

resque_config = YAML.load_file(Rails.root + 'config/resque.yml')[rails_env].symbolize_keys
Resque.redis = Redis.new(resque_config)
Resque.redis.namespace = "resque:OpenlyLocal"

# Resque::Server.use Rack::Auth::Basic do |username, password|
#   AUTHENTICATED_USERS[username].first == password
# end
require 'resque/server'

# Consider using: https://github.com/lantins/resque-retry
# https://github.com/defunkt/resque/wiki/Failure-Backends
require 'resque/failure/multiple'
require 'resque/failure/airbrake'
require 'resque/failure/redis'
Resque::Failure::Airbrake.configure do |config|
  config.api_key = '3f276ee6addc559ee3f05304075c7798'
  config.secure = true
end
Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake]
Resque::Failure.backend = Resque::Failure::Multiple

rails_env = ENV['RAILS_ENV'] || 'development'

resque_config = YAML.load_file(Rails.root + 'config/resque.yml')[rails_env].symbolize_keys
Resque.redis = Redis.new(resque_config)
Resque.redis.namespace = "resque:OpenlyLocal"

# Resque::Server.use Rack::Auth::Basic do |username, password|
#   AUTHENTICATED_USERS[username].first == password
# end
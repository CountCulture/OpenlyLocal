require 'resque/server'

# Consider using: https://github.com/lantins/resque-retry
# https://github.com/defunkt/resque/wiki/Failure-Backends
require 'resque/failure/multiple'
require 'resque/failure/airbrake'
require 'resque/failure/redis'
Resque::Failure::Airbrake.configure do |config|
  config.api_key = 'REPLACE_WITH_YOUR_AIRBRAKE_KEY'
  config.secure = true
end
Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake]
Resque::Failure.backend = Resque::Failure::Multiple

rails_env = ENV['RAILS_ENV'] || 'development'

resque_config = YAML.load_file(Rails.root + 'config/resque.yml')[rails_env].symbolize_keys
Resque.redis = Redis.new(resque_config)
Resque.redis.namespace = "resque:OpenlyLocal"

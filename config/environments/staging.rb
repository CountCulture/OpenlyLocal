require 'ipaddr'
# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# rotate logs before they get too big
config.logger = Logger.new("#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log", 20, 1048576)

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.log_level = :debug

# Use a different cache store in production
# config.cache_store = :mem_cache_store
ActionController::Base.cache_store = :file_store, "tmp/cache"

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.openlylocal.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

GOOGLE_AJAX_API_KEY = "ABQIAAAAYhi-TEPJXOrUvUXuOYmKvBQ4D8-PNYlzqSn0AArojcHa2MjuiBQCc1j3ImPBGUOFsRz7rKOIl7LvLQ"

config.middleware.use "Rack::Bug",
                      :secret_key => "Sysar9OsD+OAsolAIXLxtBV/vdJ4NXs6w9+k9sFULPPpI8ibpjdm8kAfSo3ZfwbF5LhYvNEHbqyaZqhthRZ7IQ==",
                      :ip_masks   => [IPAddr.new("127.0.0.1"), IPAddr.new("192.168.1.65")],
                      :password   => "trib4L9"
Airbrake.configure do |config|
  config.environment_filters << 'rack-bug.*'
end

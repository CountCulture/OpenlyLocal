# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

ActionController::Base.cache_store = :file_store, "tmp/cache"

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# uncomment if testing mailer
# config.action_mailer.raise_delivery_errors = true
# config.action_mailer.perform_deliveries = true
# config.action_mailer.delivery_method = :smtp

# rotate logs before they get too big
config.logger = Logger.new("#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log", 20, 1048576)

GOOGLE_AJAX_API_KEY = "ABQIAAAAYhi-TEPJXOrUvUXuOYmKvBT2yXp_ZAY8_ufC3CFXhHIE1NvwkxS7paT1EaRByac-3KQNBePyC9zQwA"

config.middleware.use "Rack::Bug",
                      :secret_key => "Sysar9OsD+OAsolAIXLxtBV/vdJ4NXs6w9+k9sFULPPpI8ibpjdm8kAfSo3ZfwbF5LhYvNEHbqyaZqhthRZ7IQ==",
                      :password   => "trib4L9"
HoptoadNotifier.configure do |config|
   config.environment_filters << 'rack-bug.*'
 end

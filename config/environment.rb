# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # You have to specify the :lib option for libraries, where the Gem name (sqlite3-ruby) differs from the file itself (sqlite3)
  config.gem "geokit"
  config.gem "hpricot"
  config.gem 'whenever', :lib => false#, :source => 'http://gemcutter.org'
  config.gem 'fastercsv'
  config.gem 'googlecharts', :lib => "gchart"
  config.gem "newrelic_rpm"
  config.gem "twitter"
  config.gem "httpclient"
  config.gem 'crack'
  config.gem "pauldix-feedzirra", :lib => "feedzirra", :source => 'http://gems.github.com'
  config.gem 'will_paginate', :version => '~> 2.3.11', :source => 'http://gemcutter.org'
  config.gem "acts-as-taggable-on", :source => 'http://gemcutter.org'
  config.gem 'hoptoad_notifier'
  config.gem 'nokogiri', :version => '~> 1.4.1'
  config.gem 'sitemap_generator', :lib => false
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.autoload_paths += %W( #{RAILS_ROOT}/app/models/observers #{RAILS_ROOT}/app/models/user_submission_types)

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  # config.time_zone = 'UTC'
  config.time_zone = 'London'
  # The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :key => '_twfy_local_parser_session',
    :secret      => '7be73fc5eb2b6c69ebcf8bea5deec5a4ad4215c820a3bd42837ebf2ce4360c9d3996b12fa4b1228f24969fbfc87d68d5c48d274819430bec7c3bfafec8ab25aa'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # Please note that observers generated using script/generate observer need to have an _observer suffix
  config.active_record.observers = :financial_transaction_observer
end
require 'open-uri'
require 'company_utilities' #phusion passenger seems to require this

Dir.glob(RAILS_ROOT + '/app/models/user_submission_types/*') {|file| require File.basename(file, '.rb')} #YAML serialisation requires this in order to instantiate objects properly on deserialisation

# require 'twitter/console'

# set default host for Action mailer so can have urls in emails
class ActionMailer::Base
  default_url_options[:host] = "openlylocal.com"
end

# Add custom date/time formats
Time::DATE_FORMATS[:event_date] = "%b %e %Y, %l.%M%p" # add custom time format so we get some unity
Date::DATE_FORMATS[:event_date] = "%b %e %Y" # add custom date format too
Time::DATE_FORMATS[:vevent] = "%Y-%m-%dT%H:%M:%S" 
Date::DATE_FORMATS[:vevent] = "%Y-%m-%dT%H:%M:%S" 
Date::DATE_FORMATS[:custom_short] = "%B %e %Y" # add custom time format so we get some unity
Time::DATE_FORMATS[:custom_short] = "%B %e %Y, %l.%M%p" # add custom time format so we get some unity
Date::DATE_FORMATS[:month_and_year] = "%b %y" # add custom time format so we get some unity

Pingback.save_callback do |ping|
    RelatedArticle.process_pingback(ping)
end

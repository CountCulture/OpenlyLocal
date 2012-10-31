source :rubygems

gem 'rails', '2.3.14'

gem 'fastercsv' # Ruby 1.8.7 optimization
gem 'json'
gem 'rubyzip', :require => false
gem 'sitemap_generator', :require => false
gem 'SystemTimer' # not sure what gem needs this

# Database/Spatial
gem 'pg'
gem 'rgeo'
gem 'spatial_adapter' # switch to activerecord-postgis-adapter in Rails 3
gem 'geokit'
gem 'dbf', '1.2.9'
gem 'georuby' # remove after switching from spatial_adapter in Rails 3

# Background jobs
gem 'daemons', '1.0.10' # used by delayed_job
gem 'delayed_job', '2.0.4'
gem 'resque', :require => 'resque/server'
gem 'resque-lock-timeout'
gem 'whenever', :require => false

# Models
gem 'acts-as-taggable-on' # FeedEntry
gem 'feedzirra' # FeedEntry
gem 'twitter', '~> 0.9' # Tweeter

# Mailers
gem 'dkim'

# Scrapers
gem 'hpricot'
gem 'httpclient'
gem 'nokogiri', '~>1.4.1'

# Utilities
gem 'companies-house' # CompanyUtilities
gem 'crack' # NpiaUtilities
gem 'rdf', :require => false # RdfUtilities
gem 'rdf-rdfxml', :require => false # RdfUtilities

# Views/Helpers
gem 'googlecharts', :require => 'gchart'
gem 'will_paginate', '~> 2.3.11'

# Production
gem 'airbrake'
gem 'capistrano'
gem 'capistrano-ext'
gem 'newrelic_rpm'

group :test do
  gem 'guard'
  gem 'guard-test'
  # gem 'minitest', '~>2.8'
  # gem 'guard-minitest'
  gem 'ruby-prof'
  gem 'shoulda'
  gem 'mocha', :require => false
  gem 'factory_girl'
end

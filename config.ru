# Taken in part from https://gist.github.com/1723954

require ::File.expand_path('../config/environment',  __FILE__)
require "resque/server"
 
app_name = Rack::Builder.new do
  use Rails::Rack::LogTailer
  use Rails::Rack::Static
  run ActionController::Dispatcher.new
end

Resque::Server.use Rack::Auth::Basic do |username, password|
  AUTHENTICATED_USERS[username] && (AUTHENTICATED_USERS[username].first == password)
end

run Rack::URLMap.new \
  "/"       => app_name,
  "/admin/resque" => Resque::Server.new
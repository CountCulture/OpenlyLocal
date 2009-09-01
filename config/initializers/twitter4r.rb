Twitter::Client.configure do |conf| 
  conf.application_name = 'OpenlyLocal' 
  conf.application_url = 'http://openlylocal.com/'
  conf.host = RAILS_ENV == "production" ? "twitter.com" : "localhost"
end
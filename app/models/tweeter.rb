class Tweeter
  attr_accessor :message, :url, :options
  def initialize(message, options={})
    @message = message
    @url = options.delete(:url)
    @options = options
  end

  def perform
    auth_details = YAML.load_file(File.join(RAILS_ROOT, 'config', 'twitter.yml'))[RAILS_ENV]
    auth = Twitter::HTTPAuth.new(auth_details['login'], auth_details['password'])
    
    # config = ConfigStore.new("#{ENV['HOME']}/.twitter")
    # oauth = Twitter::OAuth.new(config['token'], config['secret'])
    # oauth.authorize_from_access(config['atoken'], config['asecret'])
    # 
    client = Twitter::Base.new(auth)
    @message += " " + shorten_url(url) unless url.blank?
    response = client.update(message, options)
    RAILS_DEFAULT_LOGGER.info "Tweeted message: #{message}\n response: #{response.inspect}"
    response
  end
  
  private
  def shorten_url(link)
    return "" if link.blank?
    short_link = open('http://bit.ly/api?url=' + link, "UserAgent" => "Ruby-ShortLinkCreator").read
  end
end

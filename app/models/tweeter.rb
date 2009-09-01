class Tweeter
  attr_accessor :message, :url
  def initialize(message, options={})
    @message = message
    @url = options[:url]
  end

  def perform
    config_file = File.join(RAILS_ROOT, 'config', 'twitter.yml')
    twitter = Twitter::Client.from_config(config_file, RAILS_ENV)
    @message += " " + shorten_url(url) unless url.blank?
    twitter.status(:post, message)
    RAILS_DEFAULT_LOGGER.debug "Tweeted message: #{message}"
  end
  
  private
  def shorten_url(link)
    return "" if link.blank?
    short_link = open('http://bit.ly/api?url=' + link, "UserAgent" => "Ruby-ShortLinkCreator").read
  end
end

class Tweeter
  attr_accessor :message, :url, :options, :twitter_method
  def initialize(message_or_hash, options={})
    options, @message = message_or_hash.is_a?(Hash) ? [message_or_hash, nil] : [options, message_or_hash]
    @url = options.delete(:url)
    @twitter_method = options.delete(:method)
    @options = options
  end

  def perform
    @message += " " + (shorten_url(url)||url) unless url.blank?
    response = twitter_method ? self.send(twitter_method.to_sym, options) : client.update(message, options)
    RAILS_DEFAULT_LOGGER.info "Tweeted message: #{message}\n response: #{response.inspect}"
    response
  end
  
  def add_to_list(options={})
    user = Twitter.user(options[:user])
    client.list_add_member(client.client.username, options[:list], user["id"])
  end
  
  def remove_from_list(options={})
    user = Twitter.user(options[:user])
    client.list_remove_member(client.client.username, options[:list], user["id"])
  end
  
  def client(twitter_account="OpenlyLocal")
    return @client if @client
    auth_details = YAML.load_file(File.join(RAILS_ROOT, 'config', 'twitter.yml'))[RAILS_ENV][twitter_account]
    oauth = Twitter::OAuth.new(auth_details['auth_token'], auth_details['auth_secret'])
    oauth.authorize_from_access(TWITTER_OPENLYLOCAL_ACCESS_TOKEN,TWITTER_OPENLYLOCAL_ACCESS_SECRET)
    @client = Twitter::Base.new(oauth)
  end

  private
  def shorten_url(link)
    return "" if link.blank?
    UrlSquasher.new(link).result
  end
  
end

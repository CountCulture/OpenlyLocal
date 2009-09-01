class Tweeter
  attr_reader :message
  def initialize(message)
    @message = message
  end

  def perform
    config_file = File.join(RAILS_ROOT, 'config', 'twitter.yml')
    twitter = Twitter::Client.from_config(config_file, RAILS_ENV)
    twitter.status(:post, message)
    RAILS_DEFAULT_LOGGER.debug "Tweeted message: #{message}"
  end
end

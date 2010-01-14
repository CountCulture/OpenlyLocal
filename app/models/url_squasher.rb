# Bit.ly API uses URLs like: 
# http://api.bit.ly/shorten?version=2.0.1&longUrl=http://cnn.com&login=bitlyapidemo&apiKey=R_0da49e0a9118ff35f52f629d2d71bf07
# See http://code.google.com/p/bitly-api/wiki/ApiDocumentation
class UrlSquasher
  BASE_URL = "http://api.bit.ly/shorten?"
  VERSION = "2.0.1"
  def initialize(long_url)
    @long_url = long_url
  end
  
  def result
    req_url = BASE_URL + "version=#{VERSION}" + "&longUrl=#{URI.escape(@long_url)}" + "&login=#{BITLY_LOGIN}" + "&apiKey=#{BITLY_API_KEY}"
    return unless response = _http_get(req_url)
    _url_from(response)
  end
  
  protected
  def _http_get(api_url)
    return if RAILS_ENV=="test"
    RAILS_DEFAULT_LOGGER.debug "About to get query Bit.ly url: #{api_url}"
    open(api_url).read
  rescue Exception => e
    RAILS_DEFAULT_LOGGER.error "Problem shortening URL: #{@long_url}: #{e.inspect}"
  end
  
  def _url_from(response)
    RAILS_DEFAULT_LOGGER.debug "About to parse response from Bit.ly: #{response}"
    parsed_response = JSON.parse(response)
    parsed_response["results"][@long_url]["shortUrl"]
  rescue Exception => e
    RAILS_DEFAULT_LOGGER.error "Problem parsing Bit.ly response: #{parsed_response.inspect}"
    nil
  end
end
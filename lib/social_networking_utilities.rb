module SocialNetworkingUtilities
  # Finds social networking, news_feeds on given page
  class Finder
    TwitterRegexp = /twitter\.com\/([^\/\s]+)\/?$/ #there may be links to timeline
    FacebookRegexp = /facebook\.com\/([^\/\s]+)\/?$/ #there may be links to timeline
    
    attr_reader :url
    def initialize(url)
      @url = url
    end
    
    def process
      host_domain_regexp = Regexp.new(Regexp.escape(URI.parse(url).host))
      doc = Hpricot.parse(_http_get(url))
      result = {}
      twitter_account_link = doc.search('a[@href*="twitter.com/"]').detect{ |l| l[:href].match(TwitterRegexp) }
      facebook_account_link = doc.search('a[@href*="facebook.com/"]').detect{ |l| l[:href].match(FacebookRegexp) }
      twitter_account_name = extract_data(twitter_account_link, TwitterRegexp)
      facebook_account_name = extract_data(facebook_account_link, FacebookRegexp)
      feed_url = doc.search("link[@type*='rss']").collect{|l| l[:href].match(host_domain_regexp)&&l[:href] }.first
      
      { :twitter_account_name => twitter_account_name, 
        :facebook_account_name => facebook_account_name,
        :feed_url => feed_url }
    end
    
    protected
    def _http_get(target_url)
      return if RAILS_ENV=='test' # don't make calls in test env
      open(url).read
    end
    
    private
    def extract_data(link, regex)
      return if link.blank?
      link[:href].scan(regex).to_s
    end
  end
  
end
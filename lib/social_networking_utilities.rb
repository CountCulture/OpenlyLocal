module SocialNetworkingUtilities
  TwitterRegexp = /twitter\.com\/([^\/\s]+)\/?$/ #there may be links to timeline
  FacebookRegexp = /facebook\.com\/([^\/\s\.]+)\/?$/
  YoutubeRegexp = /youtube\.com\/(?:user\/)?([^\/\s]+)\/?$/ 
  
  Parsers = { :twitter_account_name => TwitterRegexp, 
              :facebook_account_name => FacebookRegexp,
              :youtube_account_name => YoutubeRegexp }
  
  module Base
    module ClassMethods
    end
    
    module InstanceMethods
      def update_social_networking_details(details_or_hash)
        attribs = details_or_hash.respond_to?(:attributes) ? details_or_hash.attributes : details_or_hash
        non_nil_attribs = attribs.delete_if { |k,v| v.blank?||!respond_to?(k) }
        update_attributes(non_nil_attribs)
      end
      
      def update_social_networking_details_from_website
        return unless url = self.url
        details = SocialNetworkingUtilities::Finder.new(url).process
        update_social_networking_details(details)
      end
      
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :include, TwitterAccountMethods
    end
  end            
              
  # Finds social networking, news_feeds on given page
  class Finder
    
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
      youtube_account_link = doc.search('a[@href*="youtube.com/"]').detect{ |l| l[:href].match(YoutubeRegexp) }
      twitter_account_name = extract_data(twitter_account_link, TwitterRegexp)
      facebook_account_name = extract_data(facebook_account_link, FacebookRegexp)
      youtube_account_name = extract_data(youtube_account_link, YoutubeRegexp)
      feed_url = doc.search("link[@type*='rss']").collect{|l| l[:href].match(host_domain_regexp)&&l[:href] }.first
      
      { :twitter_account_name => twitter_account_name, 
        :facebook_account_name => facebook_account_name,
        :youtube_account_name => youtube_account_name,
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
  
  module IdExtractor
    extend self
    def extract_from(*urls)
      urls = urls.flatten.compact
      return {} if urls.blank?
      result_hash = {}
      urls.each do |url|
        Parsers.each do |k,rx|
          s_id = url.scan(rx).to_s
          result_hash[k] = s_id unless s_id.blank?
        end
      end
      result_hash
    end
  end
  
end
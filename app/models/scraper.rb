# Scrapers are normally run as delayed_job, determined by the priority and then by the next_due date
# Scrapers of priority of less than 1 are never added to the delayed_job queue. These are principally CsvScrapers,
# which we are only ever run manually. We also don't currently add problematic ones to the queue.
class Scraper < ActiveRecord::Base
  class ScraperError < StandardError; end
  class RequestError < ScraperError; end
  class ParsingError < ScraperError; end
  SCRAPER_TYPES = %w(InfoScraper ItemScraper CsvScraper)
  USER_AGENT = "Mozilla/4.0 (OpenlyLocal.com)"
  PARSING_LIBRARIES = { 'H' => 'Hpricot', 
                        'N' => 'Nokogiri (HTML)',
                        'X' => 'Nokogiri (XML)'
                      }
  belongs_to :parser
  belongs_to :council
  validates_presence_of :council_id
  named_scope :stale, lambda {{ :conditions => ["priority > 0 AND (next_due IS NULL OR next_due < ?)", Time.now], :order => "priority, next_due" }}
  named_scope :problematic, { :conditions => { :problematic => true } }
  named_scope :unproblematic, { :conditions => { :problematic => false } }
  # accepts_nested_attributes_for :parser
  attr_accessor :related_objects, :parsing_results
  attr_protected :results
  delegate :result_model, :to => :parser, :allow_nil => true
  delegate :related_model, :to => :parser, :allow_nil => true
  delegate :portal_system, :to => :council, :allow_nil => true
  
  def validate
    errors.add(:parser, "can't be blank") unless parser
  end
  
  def base_url
    self[:base_url].blank? ? council&&council.base_url : self[:base_url]
  end
  
  def computed_cookie_url
    !base_url.blank?&&!parser.cookie_path.blank? ? "#{base_url}#{parser.cookie_path}" : nil
  end
  
  def computed_url
    !base_url.blank?&&!parser.path.blank? ? "#{base_url}#{parser.path}" : nil
  end
  
  # build url from council's base_url and parsers path unless url is set
  def cookie_url
    self[:cookie_url].blank? ? computed_cookie_url : self[:cookie_url]
  end
  
  def expected_result_attributes
    read_attribute(:expected_result_attributes) ? Hash.new.instance_eval("merge(#{read_attribute(:expected_result_attributes)})") : {}
  end
  
  def title
    "#{result_model} #{self.class.to_s.underscore.humanize}" + (council ? " for #{council.short_name}" : '')
  end
  
  def parser_attributes=(attribs={})
    parser_type = attribs[:type].blank? ? 'Parser' : attribs[:type]
    if parser
      self.parser.update_attributes(attribs)
    else
      self.parser = parser_type.constantize.new(attribs)
    end
  end
  
  def parsing_errors
    parser.errors
  end
  
  # Returns true if associated parser belongs to portal_system, false otherwise
  def portal_parser?
    !!parser.try(:portal_system)
  end
  
  def possible_parsers
    portal_system.parsers
  end
  
  def process(options={})
    mark_as_unproblematic # clear problematic flag. It will be reset if there's a prob
    # self.parsing_results = parser.process(_data(url), self, :save_results => options[:save_results]).results
    self.parsing_results = parser.process(_data(target_url_for(self)), self, :save_results => options[:save_results]).results
    update_with_results(parsing_results, options)
    update_last_scraped if options[:save_results]&&parser.errors.empty?
    mark_as_problematic unless parser.errors.empty?
    self
  rescue ScraperError => e
    logger.debug { "*******#{e.message} while processing #{self.inspect}: #{e.backtrace}" }
    errors.add_to_base(e.message)
    mark_as_problematic
    self
  end
  
  def perform
    process(:save_results => true)
    ScraperMailer.deliver_scraping_report!(self)
  end
  
  def results
    @results ||=[]
  end
  
  def results_summary
    return if results.blank?
    changed_count, error_count, new_count = 0, 0, 0
    results.each do |result|
      case result.status
      when /errors/
        error_count+=1
      when /new/
        new_count+=1
      when /\bchanged/
        changed_count +=1
      end
    end
    return "No changes" if changed_count+error_count+new_count == 0
    res = []
    res << "#{new_count} new records" if new_count > 0
    res << "#{error_count} errors" if error_count > 0
    res << "#{changed_count} changes" if changed_count > 0
    res.join(", ")
  end
  
  def scraping_for
    "#{result_model}s from <a href='#{url}'>#{url}</a>"
  end
    
  def sibling_scrapers
    council.scrapers - [self]
  end
  
  def stale?
    !next_due||(next_due < Time.now)
  end
  
  # Returns status as string (for use in css_class)
  def status
    return "stale problematic" if stale?&&problematic?
    return "stale" if stale?
    return "problematic" if problematic?
  end
  
  # build url from council's base_url and parsers path unless url is set
  def url
    self[:url].blank? ? computed_url : self[:url]
  end
  
  protected
  def _data(target_url=nil)
    begin
      options = { "User-Agent" => USER_AGENT, :cookie_url => cookie_url&&interpolate_url(cookie_url, self) } # submit interpolated cookie url if there is one
      (options["Referer"] = (referrer_url =~ /^http/ ? referrer_url : target_url)) unless referrer_url.blank?
      page_data = use_post ? _http_post_from_url_with_query_params(target_url, options) : _http_get(target_url, options)
    rescue Exception => e
      error_message = "**Problem getting data from #{target_url}: #{e.inspect}\n #{e.backtrace}"
      logger.error { error_message }
      raise RequestError, error_message
    end
    
    begin
      case parsing_library
      when 'N'
        Nokogiri.HTML(page_data)
      when 'X'
        Nokogiri.XML(page_data)
      else
        Hpricot.parse(page_data, :fixup_tags => true)
      end
    rescue Exception => e
      logger.error { "Problem with data returned from #{target_url}: #{e.inspect}" }
      raise ParsingError
    end
  end
  
  def _http_get(target_url, options={})
    return false if RAILS_ENV=="test"  # make sure we don't call make calls to external services in test environment. Mock this method to simulate response instead
    client = HTTPClient.new
    cookie_url = options.delete(:cookie_url)
    client.get_content(cookie_url) unless cookie_url.blank? # pick up cookie if we've been passed a url
    logger.debug { "Getting data using GET from #{target_url} with options: #{options.inspect}" }
    client.get_content(target_url, nil, options)
  end
  
  def _http_post_from_url_with_query_params(target_url, options={})
    return false if RAILS_ENV=="test"  # make sure we don't call make calls to external services in test environment. Mock this method to simulate response instead
    uri, params = convert_url_with_query_params(target_url)
    client = HTTPClient.new
    cookie_url = options.delete(:cookie_url)
    unless cookie_url.blank? # pick up cookie if we've been passed a url
      c_uri, c_params = convert_url_with_query_params(cookie_url)
      logger.debug { "Getting cookie using POST from #{c_uri} with params #{c_params.inspect} and options: #{options.inspect}" }
      client.post_content(c_uri, c_params)
    end
    logger.debug { "Getting data using POST from #{uri} with params #{params.inspect} and options: #{options.inspect}" }
    client.post_content(uri, params, options)
  end
  
  def update_with_results(parsing_results, options={})
    unless parsing_results.blank?
      # add result array returned from model to existing results (generated by previous call, for example when getting items assoc with related item)
      @results = results + result_model.constantize.build_or_update(parsing_results, options.merge(:organisation => council))
    end
  end

  private
  def convert_url_with_query_params(url)
    logger.debug { "***********Converting #{url} to uri and query params" }
    uri = URI.parse(url)
    params = CGI.parse(uri.query)
    uri.query = nil # reset queries as we submit as post params
    [uri, params]
  end
  
  # marks as problematic without changing timestamps
  def mark_as_problematic
    self.class.update_all({ :problematic => true }, { :id => id })
  end
  
  # marks as unproblematic without changing timestamps
  def mark_as_unproblematic
    self.class.update_all({ :problematic => false }, { :id => id })
  end
  
  def update_last_scraped
    self.class.update_all({ :next_due => (Time.zone.now + frequency.days) }, { :id => id })
    self.class.update_all({ :last_scraped => Time.zone.now }, { :id => id })
  end
  
  def target_url_for(obj=nil)
    url.blank? ? obj.url : interpolate_url(url, obj) # if we have url evaluate it AS A STRING in context of related object (which allows us to interpolate uid etc), otherwise just use related object's url
  end
  
  def interpolate_url(url, obj)
    obj.instance_eval("\"" + url + "\"")
  end
end

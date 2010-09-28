class Scraper < ActiveRecord::Base
  class ScraperError < StandardError; end
  class RequestError < ScraperError; end
  class ParsingError < ScraperError; end
  SCRAPER_TYPES = %w(InfoScraper ItemScraper)
  USER_AGENT = "Mozilla/4.0 (OpenlyLocal.com)"
  belongs_to :parser
  belongs_to :council
  validates_presence_of :council_id
  named_scope :stale, lambda { { :conditions => ["(last_scraped IS NULL) OR (last_scraped < ?)", 7.days.ago], :order => "last_scraped" } }
  named_scope :problematic, { :conditions => { :problematic => true } }
  named_scope :unproblematic, { :conditions => { :problematic => false } }
  # accepts_nested_attributes_for :parser
  attr_accessor :related_objects, :parsing_results
  attr_protected :results
  delegate :result_model, :to => :parser
  delegate :related_model, :to => :parser
  delegate :portal_system, :to => :council
  delegate :base_url, :to => :council
  
  def validate
    errors.add(:parser, "can't be blank") unless parser
  end
  
  def computed_url
    !base_url.blank?&&!parser.path.blank? ? "#{base_url}#{parser.path}" : nil
  end
  
  def expected_result_attributes
    read_attribute(:expected_result_attributes) ? Hash.new.instance_eval("merge(#{read_attribute(:expected_result_attributes)})") : {}
  end
  
  def title
    getting = self.is_a?(InfoScraper) ? 'Info' : 'Items'
    "#{result_model} #{getting} scraper for #{council.short_name}"
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
    self.parsing_results = parser.process(_data(url), self).results
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
  
  def sibling_scrapers
    council.scrapers - [self]
  end
  
  def stale?
    !last_scraped||(last_scraped < 7.days.ago)
  end
  
  # Returns status as string (for use in css_class)
  def status
    return "stale problematic" if stale?&&problematic?
    return "stale" if stale?
    return "problematic" if problematic?
  end
  
  # build url from council's base_url and parsers path unless url is set
  def url
    read_attribute(:url).blank? ? computed_url : read_attribute(:url)
  end
  
  protected
  def _data(target_url=nil)
    begin
      options = { "User-Agent" => USER_AGENT, :cookie_url => cookie_url }
      (options["Referer"] = (referrer_url =~ /^http/ ? referrer_url : target_url)) unless referrer_url.blank?
      logger.debug { "Getting data from #{target_url} with options: #{options.inspect}" }
      page_data = _http_get(target_url, options)
    rescue Exception => e
      error_message = "**Problem getting data from #{target_url}: #{e.inspect}\n #{e.backtrace}"
      logger.error { error_message }
      raise RequestError, error_message
    end
    
    begin
      Hpricot.parse(page_data, :fixup_tags => true)
    rescue Exception => e
      logger.error { "Problem with data returned from #{target_url}: #{e.inspect}" }
      raise ParsingError
    end
  end
  
  def _http_get(target_url, options={})
    return false if RAILS_ENV=="test"  # make sure we don't call make calls to external services in test environment. Mock this method to simulate response instead
    # response = nil 
    # target_url = URI.parse(target_url)
    # request = Net::HTTP.new(target_url.host, target_url.port)
    # request.read_timeout = 5 # set timeout at 5 seconds
    # begin
    #   response = request.get(target_url.request_uri)
    #   raise RequestError, "Problem retrieving info from #{target_url}." unless response.is_a? Net::HTTPSuccess
    # rescue Timeout::Error
    #   raise RequestError, "Timeout::Error retrieving info from #{target_url}."
    # end
    client = HTTPClient.new
    cookie_url = options.delete(:cookie_url)
    client.get_content(cookie_url) unless cookie_url.blank? # pick up cookie if we've been passed a url
    client.get_content(target_url, nil, options)
    # open(target_url, options).read
    # logger.debug "********Scraper response = #{response.body.inspect}"
    # response.body
  end
  
  def update_with_results(parsing_results, options={})
    unless parsing_results.blank?
      # add result array returned from model to exising results (generated by previous call, for example when getting items assoc with related item)
      @results = results + result_model.constantize.build_or_update(parsing_results, options.merge(:council_id => council_id))
    end
  end

  private
  # marks as problematic without changing timestamps
  def mark_as_problematic
    self.class.update_all({ :problematic => true }, { :id => id })
  end
  
  # marks as unproblematic without changing timestamps
  def mark_as_unproblematic
    self.class.update_all({ :problematic => false }, { :id => id })
  end
  
  def update_last_scraped
    self.class.update_all({ :last_scraped => Time.zone.now }, { :id => id })
  end
  
  def target_url_for(obj=nil)
    url.blank? ? obj.url : obj.instance_eval("\"" + url + "\"") # if we have url evaluate it AS A STRING in context of related object (which allows us to interpolate uid etc), otherwise just use related object's url
  end
end

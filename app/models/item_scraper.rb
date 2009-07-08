class ItemScraper < Scraper
  # validates_presence_of :url, :if => Proc.new { |i| i.related_model.blank? }
  
  def process(options={})
    if related_model.blank?
      super
    else
      related_objects.each do |obj|
        raw_results = parser.process(_data(target_url_for obj), self).results
        logger.debug { "\n\n**************RESULTS from parsing #{target_url_for(obj)}:\n#{raw_results.inspect}" }
        update_with_results(raw_results.collect{ |r| r.merge("#{obj.class.to_s.downcase}_id".to_sym => obj.id) }, options) unless raw_results.blank?
      end
      update_last_scraped if options[:save_results]&&parser.errors.empty?
      mark_as_problematic unless parser.errors.empty?
      self
    end
  rescue ScraperError => e
    logger.debug { "*******#{e.message} while processing #{self.inspect}" }
    errors.add_to_base(e.message)
    mark_as_problematic
    self
  end

  def related_objects
    @related_objects ||= related_model.constantize.find(:all, :conditions => { :council_id => council_id })
  end
  
  def scraping_for
    "#{result_model}s from <a href='#{url}'>#{url}</a>"
  end
    
end
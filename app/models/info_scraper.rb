class InfoScraper < Scraper
  
  def process(options={})
    mark_as_unproblematic # clear problematic flag. It will be reset if there's a prob
    @related_objects = [options[:objects]].flatten if options[:objects]
    @objects_with_errors_count = 0
    related_objects.each do |obj|
      begin
        raw_results = parser.process(_data(target_url_for(obj)), self).results
      rescue ScraperError => e
        logger.debug { "*******#{e.message} while processing #{self.inspect}" }
        obj.errors.add_to_base(e.message)
      end
      update_with_results(raw_results, obj, options)
    end
    errors.add_to_base("Problem on all items (see below for details)") if @objects_with_errors_count == related_objects.size
    update_last_scraped if options[:save_results]&&(@objects_with_errors_count != related_objects.size)
    mark_as_problematic if options[:save_results]&&(@objects_with_errors_count == related_objects.size)
    self
  rescue Exception => e # catch other exceptions and store them for display
    mark_as_problematic if options[:save_results] # don't mark if we're just testing
    errors.add_to_base("Exception while processing:\n#{e.message}")
    logger.debug { "***Exception while processing:\n#{e.message}:\n\n#{e.backtrace}" }
    self
  end
  
  def related_objects
    case 
    when @related_objects
      @related_objects
    else
      result_model.constantize.stale.find(:all, :conditions => { :council_id => council_id })
    end
  end
  
  def scraping_for
    "info on #{result_model}s from " + (url.blank? ? "#{result_model}'s url" : "<a href='#{url}'>#{url}</a>")
  end
  
  protected
  # overrides method in standard scraper
  def update_with_results(res, obj=nil, options={})
    if !obj.errors.empty? 
      @objects_with_errors_count +=1
      results << ScrapedObjectResult.new(obj)
    elsif !@parser.errors.empty?
      @objects_with_errors_count +=1
      sor = ScrapedObjectResult.new(obj)
      sor.errors.add_to_base @parser.errors[:base]
      results << sor
    elsif !res.blank?
      first_res = res.first # results are returned as an array containing just on object. I think.
      first_res.merge!(:retrieved_at => Time.now) if obj.attribute_names.include?('retrieved_at') # update timestamp if model has one
      obj.attributes = obj.clean_up_raw_attributes(first_res)
      options[:save_results] ? obj.save : obj.valid? # don't try if we've already got errors
      results << ScrapedObjectResult.new(obj)
    end
    
  end

end
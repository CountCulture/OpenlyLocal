class ItemScraper < Scraper
  # validates_presence_of :url, :if => Proc.new { |i| i.related_model.blank? }
  
  def process(options={})
    if related_model.blank?
      super
    else
      mark_as_unproblematic # clear problematic flag. It will be reset if there's a prob
      # We need to find out foreign key for relationship
      assoc_reflektion = result_model.constantize.reflect_on_association(related_model.underscore.to_sym)
      assoc_foreign_key = (assoc_reflektion.options[:foreign_key]||assoc_reflektion.association_foreign_key).to_sym
      related_objects.each do |obj|
        begin
          raw_results = parser.process(_data(target_url_for(obj)), self).results
          logger.debug { "\n\n**************RESULTS from parsing #{target_url_for(obj)}:\n#{raw_results.inspect}" }
          update_with_results(raw_results.collect{ |r| r.merge(assoc_foreign_key => obj.id) }, options) unless raw_results.blank?
        rescue Exception => e
          logger.debug { "*******#{e.message} while processing #{self.inspect}:\n#{e.backtrace}" }
          errors.add_to_base(e.message)          
          mark_as_problematic unless e.is_a?(TimeoutError)
          nil
        end
      end
      update_last_scraped if options[:save_results]&&parser.errors.empty?
      mark_as_problematic unless parser.errors.empty?
      self
    end
  end

  def related_objects
    @related_objects ||= related_model.constantize.find(:all, :conditions => { :council_id => council_id })
  end
  
end
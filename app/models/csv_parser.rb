class CsvParser < Parser
  attr_reader :results
  serialize :attribute_mapping
  HeaderNormaliser = proc{ |h| h&&h.downcase.gsub(/[^\w\d_\s]/,'').squish.gsub(/\s/,'_') }
  # HeaderNormaliser = proc{ |h| h&&h.downcase.gsub(/[^\w\d_\s]/,'').squish.gsub(/\s/,'_') }
  # HeaderNormaliser = proc{ |h| h&&h.downcase.squish.gsub(/\s/,'_') }
  
  def attribute_mapping_object
    return [MappingObject.new] if attribute_mapping.blank?
    self.attribute_mapping.collect { |k,v| MappingObject.new(k.to_s, v) }.sort{ |a,b| a.attrib_name <=> b.attrib_name }
  end
  
  def attribute_mapping_object=(params)
    result_hash = {}
    params.each do |a|
      result_hash[a["attrib_name"].to_sym] = HeaderNormaliser.call(a["column_name"])
    end
    self.attribute_mapping = result_hash
  end
  
  def process(raw_data, scraper=nil, options={})
    @current_scraper = scraper
    self.inspect #NB This seems to stop deserialization errors, in tests, and poss in production
    result_array,dry_run = [], !options[:save_results]
    raw_data = Iconv.iconv('utf-8', 'ISO_8859-1', raw_data).to_s if raw_data.grep(/\xC2\xA3|\xA3/)
    header_converters = HeaderNormaliser
    if skip_rows
      raw_data = StringIO.new(raw_data)
      skip_rows.times {raw_data.gets}
    end
    csv_file = FasterCSV.new(raw_data, :headers => true, :header_converters => header_converters)
    data_row_number = 0
    begin
      csv_file.each do |row|
        logger.debug { "**Doing line #{csv_file.lineno}" }
        break if dry_run && data_row_number == 10
        next if row.all?{ |k,v| v.blank? } # skip blank rows
        row_hash = process_row(row)
        data_row_number +=1
        result_array << {:csv_line_number => skip_rows.to_i + csv_file.lineno, :source_url => scraper&&scraper.url}.merge(row_hash) # allow results to override source_url
      end
    rescue Exception => e
      logger.debug { "Exception raised iterating through CSV rows: #{e.inspect}\n#{e.backtrace}" }
    end
    
    # p result_array
    @results = result_array
    self
  rescue Exception => e
    message = "Exception raised parsing CSV: #{e.message}\n\n" #+
    logger.debug { "Backtrace:\n#{e.backtrace}" }
    errors.add_to_base(message.gsub(/(\.)(?=\.)/, '. ')) # NB split consecutive points because of error in Rails
    self
  end
  
  private
  def process_row(row)
    res_hash = {}
    other_attribs = row.to_hash
    attribute_mapping.each do |attrib_name,header|
      if attrib_name.to_s.match(/^value_for_(.+)/) 
        res_hash[$1.to_sym] =  header
      else
        res_hash[attrib_name] =  other_attribs.delete(header)
      end
    end
    result_model_has_other_attribs? ? other_attribs.symbolize_keys.merge(res_hash) : res_hash
  end
  
  def result_model_has_other_attribs?
    result_model.constantize.new.attribute_names.include?('other_attributes')
  end
end

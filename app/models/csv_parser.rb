class CsvParser < Parser
  attr_reader :results
  MappingObject = Struct.new(:attrib_name, :column_name, :to_param)
  serialize :attribute_mapping
  
  def attribute_mapping_object
    return [MappingObject.new] if attribute_mapping.blank?
    self.attribute_mapping.collect { |k,v| MappingObject.new(k.to_s, v) }.sort{ |a,b| a.attrib_name <=> b.attrib_name }
  end
  
  def attribute_mapping_object=(params)
    result_hash = {}
    params.each do |a|
      result_hash[a["attrib_name"].to_sym] = a["column_name"]
    end
    self.attribute_mapping = result_hash
  end
  
  def process(raw_data, scraper=nil, options={})
    @current_scraper = scraper
    result_array,dry_run = [], !options[:save_results]
    if skip_rows
      raw_data = StringIO.new(raw_data)
      skip_rows.times {raw_data.gets}
    end
    csv_file = FasterCSV.new(raw_data, :headers => true)
    data_row_number = 0
    # p scraper.parser.attribute_mapping
    csv_file.each do |row|
    # rows.each do |row|
      break if dry_run && data_row_number == 10
      next if row.all?{ |k,v| v.blank? } # skip blank rows
      res_hash = {}
      attribute_mapping.each do |k,v|
        if k.to_s.match(/^value_for_(.+)/) 
          res_hash[$1.to_sym] =  v
        else
          res_hash[k] =  row[v]
        end
      end
      data_row_number +=1
      result_array << {:csv_line_number => skip_rows.to_i + csv_file.lineno, :source_url => scraper&&scraper.url}.merge(res_hash) # allow results to override source_url
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
end

require 'pp'

# Load configuration from YAML file
fn = ARGV[1]
@config = open(fn) { |f| YAML.load(f) }

desc "Load item parser"
task :load_item_parser => :environment do
  portal_system = PortalSystem.find_or_create_by_name(@config["portal_system_name"])
#   pp p

  # Destroy the existing item parser for this portal system, if any
  portal_system.parsers.first(:conditions=>{:scraper_type => 'ItemScraper'}).try(:destroy)
  
  # Create a new item parser for this portal system
  begin
    @parser = Parser.create(
      :scraper_type =>      "ItemScraper",
      :result_model =>      "PlanningApplication",
      :portal_system =>     portal_system,
      :path =>              @config["item"]["path"],
      :cookie_path =>       @config["item"]["cookie_path"],
      :item_parser =>       @config["item"]["item_parser"],
      :attribute_parser =>  @config["item"]["attributes"]
    )
  rescue Exception => e
    puts "Error creating parser: #{e}"
  end 

#   pp @parser
  puts "Created item parser for #{portal_system.name}"
  
  # Create item scrapers for all councils using this portal system
  
  @config["councils"].each do |council_name, base_url|
    unless council = Council.find_by_normalised_title(council_name)
      puts "******* Failed to match #{council_name} to council"
      next
    end
    
    begin
      scraper = ItemScraper.create(
        :council =>           council,
        :parser =>            @parser,
        :parsing_library =>   @config["item"]["parsing_library"],
        :use_post =>          @config["item"]["http_method"].upcase == "POST" ? true : false,
        :frequency =>         2,
        :base_url =>          base_url
      )
      puts "Created item scraper for #{council_name}"
    rescue Exception => e
      puts "Error creating scraper for #{council_name}: #{e}"
    end
   
  end
  
  puts "http://localhost:3000/parsers/#{@parser.id}"
end

desc "Load info parser"
task :load_info_parser => :environment do
  portal_system = PortalSystem.find_or_create_by_name(@config["portal_system_name"])
#   pp portal_system
  
  # Destroy the existing info parser for this portal system, if any
  portal_system.parsers.first(:conditions=>{:scraper_type => 'InfoScraper'}).try(:destroy)
  
#   pp @config["info"]["fields"]
  
  @attributes = {}
  
  # Convert format of @config["info"]["fields"] (an array of hashes) into @attributes (a hash)
  @config["info"]["fields"].each do |field|
    @attributes[field[:name]] = field[:parser]
  end
  
  # Create a new info parser for this portal system
  begin
    @parser = Parser.create(
      :scraper_type =>      "InfoScraper",
      :result_model =>      "PlanningApplication",
      :portal_system =>     portal_system,
      :path =>              '',
      :cookie_path =>       '',
      :item_parser =>       @config["info"]["item_parser"],
      :attribute_parser =>  @attributes
    )
    puts "Created info parser for #{portal_system.name}"
  rescue Exception => e
    puts "Error creating parser: #{e}"
  end 
  
  # Create info scrapers for all councils using this portal system
  
  @config["councils"].each do |council_name, base_url|
    unless @council = Council.find_by_normalised_title(council_name)
      puts "******* Failed to match #{council_name} to council"
      next
    end
    
    begin
      scraper = InfoScraper.create(
        :council =>           @council,
        :parser =>            @parser,
        :parsing_library =>   @config["info"]["parsing_library"],
        :use_post =>          @config["info"]["http_method"].upcase == "POST" ? true : false,
        :frequency =>         2,
        :base_url =>          base_url
      )
      
#       pp scraper
#       
#       scraper.errors.each_full { |msg| puts msg }
      
      if scraper.id.nil?
        puts "ERROR: Didn't create info scraper for #{council_name}"
      else
        puts "Created info scraper for #{council_name}"
      end

    rescue Exception => e
      puts "Error creating scraper for #{council_name}: #{e}"
    end
   
  end
  
  puts "http://localhost:3000/parsers/#{@parser.id}"
  
end

desc "Show config"
task :show_config => :environment do
  pp @config
end
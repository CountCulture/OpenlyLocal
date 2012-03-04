require 'pp'

# run by supplying short portal system short name (used in YAML file name) as argument
# e.g rake planning_alerts:load_item_parser portal_system=caps
namespace :planning_alerts do
  
  task :load_config => :environment do
    @config = YAML.load_file(File.join(RAILS_ROOT, 'lib', 'tasks', 'config', "#{ENV['portal_system']}.yml"))
  end

  desc "Load item parser"
  task :load_item_parser => :load_config do
    portal_system = PortalSystem.find_or_create_by_name(@config["portal_system_name"])
  
    # Create or update the planning item parser for this portal system
    begin
      @parser = Parser.find_or_create_by_portal_system_id_and_result_model_and_scraper_type(
        :scraper_type =>        "ItemScraper",
        :result_model =>        "PlanningApplication",
        :portal_system_id =>    portal_system.id
      )

      @parser.update_attributes(
        :path =>                @config["item"]["path"],
        :cookie_path =>         @config["item"]["cookie_path"],
        :item_parser =>         @config["item"]["item_parser"],
        :attribute_parser =>    @config["item"]["attributes"]
      )

    rescue Exception => e
      puts "Error creating parser: #{e}"
    end 

    puts "Created item parser for #{portal_system.name}"
  
    # Create item scrapers for all councils using this portal system
  
    @config["councils"].each do |council_name, base_url|
      unless council = Council.find_by_normalised_title(council_name.gsub('_',' '))
        puts "******* Failed to match #{council_name} to council"
        next
      end
    
      begin
        scraper = ItemScraper.find_or_create_by_council_id_and_parser_id(council.id, @parser.id)
         
        scraper.update_attributes( 
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
  task :load_info_parser => :load_config do
    portal_system = PortalSystem.find_or_create_by_name(@config["portal_system_name"])
  
    @attributes = {}
  
    # Convert format of @config["info"]["fields"] (an array of hashes) into @attributes (a hash)
    @config["info"]["fields"].each do |field|
      @attributes[field[:name]] = field[:parser]
    end
  
    # Create a new info parser for this portal system
    begin
      @parser = Parser.find_or_create_by_portal_system_id_and_result_model_and_scraper_type(
        :scraper_type =>        "InfoScraper",
        :result_model =>        "PlanningApplication",
        :portal_system_id =>    portal_system.id
      )
    
      @parser.update_attributes(
        :path =>              '',
        :cookie_path =>       '',
        :item_parser =>       @config["info"]["item_parser"],
        :attribute_parser =>  @attributes
      )
      puts "Created info parser for #{portal_system.name}"
    rescue Exception => e
      puts "Error creating parser: #{e}"
      next # end this rake task
    end 
  
    # Create info scrapers for all councils using this portal system
  
    @config["councils"].each do |council_name, base_url|
      unless @council = Council.find_by_normalised_title(council_name)
        puts "******* Failed to match #{council_name} to council"
        next
      end
    
      begin
        scraper = InfoScraper.find_or_create_by_council_id_and_parser_id(@council.id, @parser.id)

        scraper.update_attributes(
          :parsing_library =>   @config["info"]["parsing_library"],
          :use_post =>          @config["info"]["http_method"].upcase == "POST" ? true : false,
          :frequency =>         2,
          :base_url =>          base_url
        )
      
        puts "Created or updated info scraper for #{council_name}"

      rescue Exception => e
        puts "Error creating scraper for #{council_name}: #{e}"
      end
   
    end
  
    puts "http://localhost:3000/parsers/#{@parser.id}"
  end
  
#   desc "Dump portal system to YAML"
#   task :dump_portal_system => :environment do
#     puts "Dumping #{ENV['portal_system']}"
#     if @portal_system = PortalSystem.find_by_name(ENV['portal_system'])
#       @output = {}
#       @output['portal_system_name'] = @portal_system.name
#       @output['councils'] = {}
#       @portal_system.councils.each do |council|
#         @output['councils'][council.normalised_title] = council.url
#         puts council.normalised_title
#         puts council.url
#       end
#       
#       puts @output.to_yaml
#     else
#       $stderr.puts "Couldn't find portal system #{ENV['portal_system']}"
#     end
#   end

  desc "Show config"
  task :show_config => :load_config do
    pp @config# = YAML.load_file(File.join(RAILS_ROOT, 'lib', 'tasks', 'config', "#{args[:portal_system_short_name]}.yml"))
  end
  
end

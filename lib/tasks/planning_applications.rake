desc "Export CSV version of planning application data"
task :export_csv_planning_applications  => :environment do
  require 'faster_csv'
  include RakeUtilities::UploadDataDumps
  csv_file = File.join(RAILS_ROOT, 'tmp', "planning_applications.csv")
  FasterCSV.open(csv_file, "w") do |csv|
    csv << PlanningApplication::csv_headings
    PlanningApplication.find_each(:include => [:council]) do |pa|
      # next unless financial_transaction.organisation.is_a?(Council) # skip non-council transactions
      begin
        csv << pa.csv_data
      rescue Exception => e
        puts "Problem converting #{pa.inspect} to csv: #{e.inspect}"
      end
      
    end
  end
  RAILS_DEFAULT_LOGGER.warn {"*** Finished exporting planning_applications to CSV file"}
  zip_and_upload_data_dump('planning_applications', :upload_path => 'sites/twfy_local/shared/data/downloads/')
end  

desc "Update CAPS planning application URLs to Idox ones"
task :convert_caps_applications_to_idox => :environment do
  puts "Please enter council name:"
  if council = Council.find_by_normalised_title(Council.normalise_title($stdin.gets.chomp))
    puts "About to convert URLs for #{council.name}"
  else
    puts "Couldn't find council"
    break
  end
  puts "Please enter sample url:"
  sample_url = $stdin.gets.chomp
  sample_old_app = council.planning_applications.first
  unless stem = sample_url[/(.*keyVal=)[A-Z0-9]+$/, 1]
    puts "Couldn't extract stem from sample url"
    break
  end
  uid = sample_old_app.url[/=([A-Z0-9]+)$/,1]
  puts "An old planning application with url #{sample_old_app.url} and address #{sample_old_app.formatted_address} will be updated with new url\n#{stem}#{uid}"
  puts "Please check that this URL is valid."
  puts "Is this correct [y/n]?"
  break unless $stdin.gets.chomp.downcase == 'y'
  council.planning_applications.find_each do |pa|
    next unless uid = pa.url[/=([A-Z0-9]+)$/,1]
    pa.update_attribute(:url, stem + uid)
    print '.'
  end
end

desc "Import last four years planning applications for Idox scrapers"
task :import_old_planning_applications => :environment do
  resp = 'N'
  while resp != 'Y' do
    puts "Please enter name of Portal System:"
    portal_system_name = $stdin.gets.chomp
    portal_system = PortalSystem.find_by_name(portal_system_name)
    puts "Portal system: #{portal_system_name}. Is this correct?"
    resp = $stdin.gets.chomp
  end
  portal_parser = PortalSystem.find_by_name(portal_system_name).parsers.first(:conditions=>{:scraper_type => 'ItemScraper'})
  puts "How many weeks do you wish to go back [4]?"
  weeks_to_import = $stdin.gets.chomp
  weeks_to_import = 4 if weeks_to_import.blank?
  scrapers = portal_parser.scrapers.all(:limit => 2)
  scrapers.each do |scraper|
    puts "About to get past planning applications for #{scraper.council.name}"
    weeks_to_import.to_i.times do |i|
      start_date, end_date = (7*i + 21).days.ago.strftime("%d/%m/%Y"), (7*i + 14).days.ago.strftime("%d/%m/%Y") 
      cookie_url = scraper.cookie_url.sub(/\#\{[^{]+\}/, start_date) # replace start date
      cookie_url = cookie_url.sub(/\#\{[^{]+\}/, end_date) # replace end date
      puts "About to process scraper from #{start_date} to #{end_date} (from #{cookie_url})"
      scraper.process(:cookie_url => cookie_url, :save_results => true)
    end
  end
end


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
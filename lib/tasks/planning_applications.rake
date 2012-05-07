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
        puts "Problem converting #{financial_transaction.inspect} to csv: #{e.inspect}"
      end
      
    end
  end
  RAILS_DEFAULT_LOGGER.warn {"*** Finished exporting planning_applications to CSV file"}
  zip_and_upload_data_dump('planning_applications', :upload_path => 'sites/twfy_local/shared/data/downloads/')
end  

desc "Get bounding boxes for wards"
task :get_bounding_boxes_for_wards => :environment do
  Ward.find_each(:conditions => 'ness_id IS NOT NULL') do |ward|
    begin
      client = NessUtilities::RestClient.new(:get_area_detail, :area_id => ward.ness_id)
      northings_eastings = client.response["AreaDetail"]["Envelope"].split(":")
      sw = OsCoordsUtilities.convert_os_to_wgs84(northings_eastings[0], northings_eastings[1])
      ne = OsCoordsUtilities.convert_os_to_wgs84(northings_eastings[2], northings_eastings[3])
      boundary = ward.boundary || ward.build_boundary
      boundary.bounding_box_from_sw_ne = [sw, ne]
      boundary.save!
      puts "Successfully created/updated boundary for ward: #{ward.name}"
    rescue Exception => e
      puts "*** Problem creating/updating boundary for #{ward.name}: #{e.inspect}"
    end
  end
end

desc "Import postcodes from CSV file"
task :import_postcodes_from_csv => :environment do
  postcode_files = Dir.new(File.join(RAILS_ROOT, 'db', 'csv_data', 'postcodes')).entries[2..-1]
  postcode_files.each do |postcode_file|
    count = 0
    postcode_base = postcode_file.sub('.csv','').upcase
    puts "About to start importing postcodes beginning #{postcode_base}"
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/csv_data/postcodes/#{postcode_file}"), :headers => false) do |row|
      postcode = Postcode.find_or_initialize_by_code(row[0].squish.upcase)
      county = row[7] == '00' ? nil : Council.find_by_snac_id(row[7])
      district = Council.find_by_snac_id(row[7]+row[8])
      ward = Ward.find_by_snac_id(row[7]+row[8]+row[9])
      postcode.update_attributes( :quality => row[1],
                                  :lat => row[2],
                                  :lng => row[3],
                                  :country => row[4],
                                  :nhs_region => row[5],
                                  :nhs_health_authority => row[6],
                                  :county_id => county&&county.id,
                                  :district_id => district&&district.id,
                                  :ward_id => ward&&ward.id)
      count += 1                             
    end
    puts "Created/Updated #{count} postcodes for area #{postcode_base}"
  end
end

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
      postcode = Postcode.find_or_initialize_by_code(row[0].sub(/\s/,'').upcase)
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
                                  :council_id => district&&district.id,
                                  :ward_id => ward&&ward.id)
      count += 1                             
    end
    puts "Created/Updated #{count} postcodes for area #{postcode_base}"
  end
end


desc "Import Ward Boundaries"
task :import_ward_boundaries => :environment do
  require 'geo_ruby'
  shpfile = File.join(RAILS_ROOT, "db/boundary_line/district_borough_unitary_ward_region")
  i=0
  GeoRuby::Shp4r::ShpFile.open(shpfile) do |shp|
          shp.each do |shape|
            # break if i>3
            geom = shape.geometry #a GeoRuby SimpleFeature
            wsg84_polygons = geom.geometries.collect do |polygon|
              wgs84_lat_long_groupings = polygon.rings.collect do |ring|
                ring.points.collect{|pt| OsCoordsNewUtilities.convert_os_to_wgs84(pt.x,pt.y).reverse } # when creating from collections of coords supplied as x,y (where x is long, y lat)
              end
              Polygon.from_coordinates(wgs84_lat_long_groupings)
            end
            boundary_line = GeoRuby::SimpleFeatures::MultiPolygon.from_polygons(wsg84_polygons)
            
            att_data = shape.data #a Hash
            # p att_data
            if !att_data['CODE'].blank? && ward = Ward.find_by_snac_id(att_data['CODE'])
              ward.create_boundary(:boundary_line => boundary_line, :hectares => att_data['HECTARES'])
              puts "Udated ward: #{ward.name} with boundary"
            else
              puts "****Could not find ward for: #{att_data.inspect}"
            end
            # i += 1
          end
  end
  # postcode_files = Dir.new(File.join(RAILS_ROOT, 'db', 'csv_data', 'postcodes')).entries[2..-1]
end
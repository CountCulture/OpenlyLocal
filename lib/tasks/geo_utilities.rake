desc "Get bounding boxes for wards"
task :get_bounding_boxes_for_wards => :environment do
  Ward.find_each(:conditions => "ness_id IS NOT NULL") do |ward|
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
  postcode_files = Dir.new(File.join(RAILS_ROOT, 'db', 'data', 'csv_data', 'postcodes')).entries[2..-1]
  postcode_files.each do |postcode_file|
    count = 0
    postcode_base = postcode_file.sub('.csv','').upcase
    puts "About to start importing postcodes beginning #{postcode_base}"
    FasterCSV.foreach(File.join(RAILS_ROOT, "db/data/csv_data/postcodes/#{postcode_file}"), :headers => false) do |row|
      postcode = Postcode.find_or_initialize_by_code(row[0].sub(/\s/,'').upcase)
      county = row[15] == '00' ? nil : Council.find_by_snac_id(row[15])
      district = Council.find_by_snac_id(row[15]+row[16])
      ward = Ward.find_by_snac_id(row[15]+row[16]+row[17])
      lat,lng = OsCoordsUtilities.convert_os_to_wgs84(row[10], row[11])
      postcode.update_attributes( :quality => row[1],
                                  :lat => lat,
                                  :lng => lng,
                                  :country => row[12],
                                  :nhs_region => row[13],
                                  :nhs_health_authority => row[14],
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
  require 'geo_ruby/shp4r/shp'
  shpfile = File.join(RAILS_ROOT, "db/data/boundary_line/district_borough_unitary_ward_region")
  i=0
  GeoRuby::Shp4r::ShpFile.open(shpfile) do |shp|
    shp.each do |shape|
      att_data = shape.data
      if !att_data['CODE'].blank?
        ward = Ward.find_by_snac_id(att_data['CODE'])
        if ward
          if ward.boundary
            puts "Already imported boundary for #{ward.name}"
          else
            geom = shape.geometry
            puts "#{geom.geometries.size} Geometries, #{geom.geometries.first.rings.size} rings"
            # wsg84_polygons = geom.geometries.collect do |polygon|
            wgs84_lat_long_groupings = geom.geometries.first.rings.collect do |ring|
              ring.points.collect{|pt| OsCoordsNewUtilities.convert_os_to_wgs84(pt.x,pt.y).reverse } # when creating from collections of coords supplied as x,y (where x is long, y lat)
            end
            wsg84_polygon = Polygon.from_coordinates(wgs84_lat_long_groupings)
            # boundary_line = GeoRuby::SimpleFeatures::MultiPolygon.from_polygons(wsg84_polygons)

            begin
              ward.create_boundary(:boundary_line => wsg84_polygon, :hectares => att_data['HECTARES'])
              puts "Updated boundary for #{ward.name}"
            rescue Exception => e
              puts "Error saving boundary: #{e.inspect}"
            end
          end
        else
          puts "***** Couldn't find ward for #{att_data.inspect}"
        end
      else
        puts "***** No CODE in #{att_data.inspect}"
      end
    end
  end
  # postcode_files = Dir.new(File.join(RAILS_ROOT, 'db', 'csv_data', 'postcodes')).entries[2..-1]
end
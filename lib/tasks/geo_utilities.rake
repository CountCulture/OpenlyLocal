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

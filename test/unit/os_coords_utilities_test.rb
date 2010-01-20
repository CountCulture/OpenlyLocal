require 'test_helper'

# http://www-users.cs.york.ac.uk/~fisher/software/coco/
# 462400.0000 E 450700.0000 N
#   --> lon -1.049118 : -1:02:56.8239 lat 53.948437 : 53:56:54.3747 datum OSGB36
#   $ datumshift -I OSGB36 -O WGS84  -1.049118 53.948437 0
# lon -1.049118 : -1:02:56.8248 lat 53.948437 : 53:56:54.3732 hgt 0.000 datum OSGB36
#   --> lon -1.050704 : -1:03:02.5341 lat 53.948647 : 53:56:55.1288 hgt 47.758 datum WGS84

class OsCoordsUtilitiesTest < Test::Unit::TestCase
  OriginalNameAndConvertedCoords = [ 
    [372533.0, 188828.0], [51.597620, -2.397938]
  ]
  
  context "The OsCoordsUtilities module" do

    should "convert OS northings and eastings to WGS84 lat, long" do
      os_coords = OriginalNameAndConvertedCoords.first
      wgs84_lat_long = OsCoordsUtilities.convert_os_to_wgs84(os_coords.first, os_coords.last)
      assert_in_delta OriginalNameAndConvertedCoords.last[0], wgs84_lat_long.first, 0.001
      assert_in_delta OriginalNameAndConvertedCoords.last[1], wgs84_lat_long.last, 0.001
    end

  end
  
end
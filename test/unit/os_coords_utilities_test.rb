require File.expand_path('../../test_helper', __FILE__)

# http://www-users.cs.york.ac.uk/~fisher/software/coco/
# 462400.0000 E 450700.0000 N
#   --> lon -1.049118 : -1:02:56.8239 lat 53.948437 : 53:56:54.3747 datum OSGB36
#   $ datumshift -I OSGB36 -O WGS84  -1.049118 53.948437 0
# lon -1.049118 : -1:02:56.8248 lat 53.948437 : 53:56:54.3732 hgt 0.000 datum OSGB36
#   --> lon -1.050704 : -1:03:02.5341 lat 53.948647 : 53:56:55.1288 hgt 47.758 datum WGS84

class OsCoordsUtilitiesTest < ActiveSupport::TestCase
  OriginalNameAndConvertedCoords = [ 
    [651409.903, 313177.27], [52.657570301933156, 1.717921580645096], [52.65797559953351, 1.7160665447977752]
  ]
  
  context "The OsCoordsNewUtilities module" do

    should "convert OS northings and eastings to OSGB36 lat, long" do
      os_coords = OriginalNameAndConvertedCoords.first
      osgb36_lat_long = OsCoordsNewUtilities.ne_to_osgb36(os_coords.first, os_coords.last)
      assert_in_delta OriginalNameAndConvertedCoords[1][0], osgb36_lat_long[0], 0.000001
      assert_in_delta OriginalNameAndConvertedCoords[1][1], osgb36_lat_long[1], 0.000001
    end

    should "convert OS northings and eastings to WGS84 lat, long" do
      os_coords = OriginalNameAndConvertedCoords.first
      wgs84_lat_long = OsCoordsNewUtilities.convert_os_to_wgs84(os_coords.first, os_coords.last)
      assert_in_delta OriginalNameAndConvertedCoords.last[0], wgs84_lat_long[0], 0.000001
      assert_in_delta OriginalNameAndConvertedCoords.last[1], wgs84_lat_long[1], 0.000001
    end

  end
  
end
class Projection
  FACTORY = RGeo::Geographic.projected_factory :projection_proj4 => '+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs'

  # @param [Float] longitude a longitude
  # @param [Float] latitude a latitude
  # @return [Point] the point reprojected to EPSG:27700
  def self.point(longitude, latitude)
    projection = FACTORY.point(longitude, latitude).projection
    Point.from_x_y(projection.x, projection.y, 27700)
  end
end

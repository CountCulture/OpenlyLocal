class Postcode < ActiveRecord::Base
  belongs_to :ward
  belongs_to :council
  belongs_to :county, :class_name => "Council", :foreign_key => "county_id"
  belongs_to :crime_area
  has_many :councillors, :class_name => "Member", :through => :ward, :source => :members
  validates_uniqueness_of :code
  validates_presence_of :code, :lat, :lng
  acts_as_mappable

  before_create :set_geom

  def self.find_from_messy_code(raw_code)
    return if raw_code.blank?
    find_by_code(raw_code.strip.gsub(/\s/,'').upcase)
  end
  
  # @return [Array<HyperlocalSite>] all hyperlocal sites within 20 miles of this
  #   postcode's centroid
  #
  # @see http://spatialreference.org/ref/epsg/27700/
  def hyperlocal_sites
    HyperlocalSite.approved.all(:conditions => ['ST_DWithin(metres, ?, 32186.9)', metres], :limit => 5, :order => "ST_Distance(geom, ST_GeomFromText('POINT(#{lng} #{lat})', 4326))")
  end
  
  def pretty_code
    pc = code.dup
    pc[-3, 0] = ' '
    pc
  end

private

  def set_geom
    if lat? && lng?
      unless geom?
        self.geom = Point.from_x_y(lng, lat, 4326)
      end
      unless metres?
        self.metres = Point.from_x_y(lng, lat, 27700)
      end
    end
  end
end

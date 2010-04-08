class Postcode < ActiveRecord::Base
  belongs_to :ward
  belongs_to :council
  belongs_to :county, :class_name => "Council", :foreign_key => "county_id"
  has_many :councillors, :class_name => "Member", :through => :ward, :source => :members
  validates_uniqueness_of :code
  validates_presence_of :code, :lat, :lng
  acts_as_mappable
  
  
  def self.find_from_messy_code(raw_code)
    find_by_code(raw_code.strip.gsub(/\s/,'').upcase)
  end
  
  def hyperlocal_sites
    HyperlocalSite.approved.find(:all, :origin => [lat,lng], :within => 20, :limit => 5, :order => 'distance')
  end
  
  def pretty_code
    pc = code.dup
    pc[-3, 0] = ' '
    pc
  end
end

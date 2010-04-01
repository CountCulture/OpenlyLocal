class Postcode < ActiveRecord::Base
  belongs_to :ward
  belongs_to :council
  belongs_to :county, :class_name => "Council", :foreign_key => "county_id"
  validates_uniqueness_of :code
  validates_presence_of :code, :lat, :lng
  
  def pretty_code
    pc = code.dup
    pc[-3, 0] = ' '
    pc
  end
end

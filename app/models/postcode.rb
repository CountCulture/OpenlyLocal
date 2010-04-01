class Postcode < ActiveRecord::Base
  validates_uniqueness_of :code
  validates_presence_of :code, :lat, :lng
end

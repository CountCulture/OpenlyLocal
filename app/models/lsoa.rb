class Lsoa < ActiveRecord::Base
  belongs_to :ward
  validates_presence_of :oa_code, :lsoa_code, :lsoa_name
  validates_uniqueness_of :oa_code
end

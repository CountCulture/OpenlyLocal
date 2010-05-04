class OutputAreaClassification < ActiveRecord::Base
  validates_presence_of :title, :uid, :level, :area_type
  validates_uniqueness_of :uid, :scope => :area_type
end

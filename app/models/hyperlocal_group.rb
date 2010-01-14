class HyperlocalGroup < ActiveRecord::Base
  has_many :hyperlocal_sites, :conditions => {:approved => true}
  validates_presence_of :title
  validates_uniqueness_of :title
end

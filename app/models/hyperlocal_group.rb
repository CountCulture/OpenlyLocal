class HyperlocalGroup < ActiveRecord::Base
  has_many :hyperlocal_sites, :conditions => {:approved => true}
  validates_presence_of :title
  validates_uniqueness_of :title

  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
end

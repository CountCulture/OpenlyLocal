class PoliceForce < ActiveRecord::Base
  has_many :councils
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  validates_uniqueness_of :url
  default_scope :order => "name"
  alias_attribute :title, :name
  
  def dbpedia_resource
    wikipedia_url.gsub(/en\.wikipedia.org\/wiki/, "dbpedia.org/resource") unless wikipedia_url.blank?
  end
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  # provide stub status method for link_for helper method
  def status
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
end

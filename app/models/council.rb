# attributes: url wikipedia_url location

class Council < ActiveRecord::Base
  has_many :members
  has_many :committees
  has_many :memberships, :through => :members
  has_many :scrapers
  has_many :meetings
  has_many :wards
  has_many :datapoints
  has_many :datasets, :through => :datapoints
  belongs_to :portal_system
  validates_presence_of :name
  validates_uniqueness_of :name
  named_scope :parsed, :conditions => "members.council_id = councils.id", :joins => "INNER JOIN members", :group => "councils.id"
  default_scope :order => "name"
  alias_attribute :title, :name
  
  def average_membership_count
    # memberships.average(:group => "members.id")
    memberships.count.to_f/members.current.count
  end
  
  def base_url
    read_attribute(:base_url) || url
  end
  
  def dbpedia_url
    wikipedia_url.gsub(/en\.wikipedia.org\/wiki/, "dbpedia.org/page") unless wikipedia_url.blank?
  end
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def parsed?
    !members.blank?
  end
  
  def short_name
    name.gsub(/Borough|City|Royal|London|of|Council/, '').strip
  end
end

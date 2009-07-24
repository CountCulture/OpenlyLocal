# attributes: url wikipedia_url location

class Council < ActiveRecord::Base
  AUTHORITY_TYPES = {
    "London Borough" => "http://en.wikipedia.org/wiki/London_borough",
    "Unitary" => "http://en.wikipedia.org/wiki/Unitary_authority",
    "District" => "http://en.wikipedia.org/wiki/Districts_of_England",
    "County" => "http://en.wikipedia.org/wiki/Non-metropolitan_county",
    "Metropolitan Borough" => "http://en.wikipedia.org/wiki/Metropolitan_borough"
  }
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
  
  def authority_type_help_url
    AUTHORITY_TYPES[authority_type]
  end
  
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
  
  def party_breakdown
    party_groups = members.group_by(&:party)
    return [] if party_groups.size==1 && (party_groups[nil]||party_groups[""]) # i.e. members but no parties
    if party_groups[nil]||party_groups[""]
      party_groups["Not known"] = party_groups[nil].to_a + party_groups[""].to_a
      party_groups.delete(nil)
      party_groups.delete("") # replace nil or blank keys with 'Not known'
    end
    breakdown = party_groups.collect{|k,v| [k, v.size]}.sort{ |x,y| y[1] <=> x[1]  }
  end
  
  def short_name
    name.gsub(/Borough|City|Royal|London|of|Council/, '').strip
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
end

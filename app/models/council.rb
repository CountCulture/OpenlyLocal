# attributes: url wikipedia_url location

class Council < ActiveRecord::Base
  AUTHORITY_TYPES = {
    "London Borough" => "http://en.wikipedia.org/wiki/London_borough",
    "Unitary" => "http://en.wikipedia.org/wiki/Unitary_authority",
    "District" => "http://en.wikipedia.org/wiki/Districts_of_England",
    "County" => "http://en.wikipedia.org/wiki/Non-metropolitan_county",
    "Metropolitan Borough" => "http://en.wikipedia.org/wiki/Metropolitan_borough"
  }
  include PartyBreakdown
  has_many :members, :order => "last_name"
  has_many :committees, :order => "title"
  has_many :memberships, :through => :members
  has_many :scrapers
  has_many :meetings
  has_many :held_meetings, :class_name => "Meeting", :conditions => 'date_held <= \'#{Time.now.to_s(:db)}\''
  has_many :wards, :order => "name"
  has_many :datapoints
  has_many :datasets, :through => :datapoints
  has_many :meeting_documents, :through => :meetings, :source => :documents, :select => "documents.id, documents.title, documents.document_type, documents.document_owner_type, documents.document_owner_id, documents.created_at, documents.updated_at", :order => "documents.created_at DESC"
  has_many :past_meeting_documents, :through => :held_meetings, :source => :documents, :order => "documents.created_at DESC"
  belongs_to :portal_system
  validates_presence_of :name
  validates_uniqueness_of :name
  named_scope :parsed, :conditions => "members.council_id = councils.id", :joins => "INNER JOIN members", :group => "councils.id"
  default_scope :order => "name"
  alias_attribute :title, :name
  alias_method :old_to_xml, :to_xml
  
  def authority_type_help_url
    AUTHORITY_TYPES[authority_type]
  end
  
  def active_committees(include_inactive=nil)
    return committees if include_inactive
    ac = committees.active
    ac.empty? ? committees : ac
  end 

  def average_membership_count
    # memberships.average(:group => "members.id")
    memberships.count.to_f/members.current.count
  end
  
  def base_url
    read_attribute(:base_url).blank? ? url : read_attribute(:base_url)
  end
  
  def dbpedia_url
    wikipedia_url.gsub(/en\.wikipedia.org\/wiki/, "dbpedia.org/page") unless wikipedia_url.blank?
  end
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/councils/#{to_param}"
  end
  
  def parsed?
    !members.blank?
  end
    
  def short_name
    name.gsub(/Borough|City|Royal|London|of|Council/, '').strip
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
  def to_xml(options={})
    old_to_xml({:except => [:base_url, :portal_system_id], :methods => [:openlylocal_url]}.merge(options))
  end
  
  def to_detailed_xml(options={})
    includes = {:members => {:only => [:id,:first_name, :last_name]}}
    [:committees, :datasets, :wards].each{ |a| includes[a] = { :only => [ :id, :title ] } }
    to_xml({:include => includes}.merge(options))
  end
  
end

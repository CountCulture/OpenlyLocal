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
  include AreaStatisticMethods
  has_many :members, :order => "last_name"
  has_many :committees, :order => "title"
  has_many :memberships, :through => :members
  has_many :scrapers
  has_many :meetings
  has_many :held_meetings, :class_name => "Meeting", :conditions => 'date_held <= \'#{Time.now.to_s(:db)}\''
  has_many :wards, :order => "name"
  has_many :officers
  has_one  :chief_executive, :class_name => "Officer", :conditions => {:position => "Chief Executive"}
  has_one  :police_authority, :through => :police_force
  has_many :old_datapoints
  has_many :old_datasets, :through => :old_datapoints
  has_many :meeting_documents, :through => :meetings, :source => :documents, :select => "documents.id, documents.title, documents.document_type, documents.document_owner_type, documents.document_owner_id, documents.created_at, documents.updated_at", :order => "documents.created_at DESC"
  has_many :past_meeting_documents, :through => :held_meetings, :source => :documents, :order => "documents.created_at DESC"
  has_many :services
  has_many :datapoints, :as => :area
  has_many :dataset_topics, :through => :datapoints
  belongs_to :parent_authority, :class_name => "Council", :foreign_key => "parent_authority_id"
  has_many :child_authorities, :class_name => "Council", :foreign_key => "parent_authority_id", :order => "name"
  has_many :hyperlocal_sites, :conditions => {:approved => true}
  belongs_to :portal_system
  belongs_to :police_force
  belongs_to :pension_fund
  validates_presence_of :name
  validates_uniqueness_of :name
  named_scope :parsed, lambda { |options| options ||= {}; options[:include_unparsed] ? 
                      { :select => 'councils.*, COUNT(members.id) AS member_count', :joins =>'LEFT JOIN members ON members.council_id = councils.id', :group => "councils.id" } : 
                      {:joins => :members, :group => "councils.id", :select => 'councils.*, COUNT(members.id) AS member_count'} }
  default_scope :order => 'name'
  alias_attribute :title, :name
  alias_method :old_to_xml, :to_xml
  
  def self.find_by_params(params={})
    country, region, term = params.delete(:country), params.delete(:region), params.delete(:term)
    conditions = term ? ["councils.name LIKE ?", "%#{term}%"] : nil
    conditions ||= {:country => country, :region => region}.delete_if{ |k,v| v.blank?  }
    parsed(:include_unparsed => params.delete(:include_unparsed)).all({:conditions => conditions}.merge(params))
  end
  
  def self.with_stale_services
    all(:joins => "LEFT JOIN services ON services.council_id=councils.id", :conditions => ["((services.id IS NULL) OR (services.updated_at < ?)) AND (councils.ldg_id IS NOT NULL)", 7.days.ago], :group => "councils.id")
  end
  
  # instance methods
  def authority_type_help_url
    AUTHORITY_TYPES[authority_type]
  end
  
  # Returns only active committees if there are active and inactive commmittees, or
  # all committees if there are no active committess (prob because there are no meetings
  # yet in system). Can be made to return all committees by passing true as argument
  def active_committees(include_inactive=nil)
    return committees.with_activity_status if include_inactive
    ac = committees.active
    ac.empty? ? committees : ac
  end 

  # Returns true if council has any active committees, i.e. if council 
  # has any meetings in past year (as meetings must be associated with committees)
  def active_committees?
    meetings.count(:conditions => ["meetings.date_held > ?", 1.year.ago]) > 0
  end
  
  def average_membership_count
    # memberships.average(:group => "members.id")
    memberships.count.to_f/members.current.count
  end
  
  def base_url
    read_attribute(:base_url).blank? ? url : read_attribute(:base_url)
  end
  
  def dbpedia_resource
    wikipedia_url.gsub(/en\.wikipedia.org\/wiki/, "dbpedia.org/resource") unless wikipedia_url.blank?
  end
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/councils/#{to_param}"
  end
  
  # A council is considered to be parsed if it has members. Note it is very inefficient to check members 
  # for each council, both on SQL queries and on member (including all members is not a good idea), so 
  # when retruning list of councils we also return member_count attribute and we use this if poss
  def parsed?
    respond_to?(:member_count) ? member_count.to_i > 0 : !members.blank?
  end
  
  def police_force_url
    self[:police_force_url].blank? ? police_force.try(:url) : self[:police_force_url]
  end
    
  def recent_activity
    conditions = ["updated_at > ?", 7.days.ago]
    { :members => members.all(:conditions => conditions),
      :committees => committees.all(:conditions => conditions),
      :meetings => meetings.all(:conditions => conditions),
      :documents => meeting_documents.all(:conditions => ["documents.updated_at > ?", 7.days.ago])}
  end
  
  # returns related councils, i.e. those of same authority type
  def related
    self.class.all(:conditions => {:authority_type => authority_type})
  end
  
  def potential_services(options={})
    return [] if ldg_id.blank?
    authority_level = (authority_type =~ /Metropolitan|London/ ? "Unitary" : authority_type)
    conditions = ["authority_level LIKE ? OR authority_level = 'all'", "%#{authority_level}%"]
    LdgService.all(:conditions => conditions, :order => "lgsl") 
  end
  
  def short_name
    return name if name =~ /City of London|Greater London Authority/
    name.gsub(/&| and|Metropolitan|Borough of|Borough|District|City of|City|County of|County|Royal|Council of the|London|Council|\([\w\s]+\)/, '').squish
  end
  
  def status
    parsed? ? "parsed" : "unparsed"
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:except => [:base_url, :portal_system_id], :methods => [:openlylocal_url]}.merge(options), &block)
  end
  
  def to_detailed_xml(options={})
    includes = {:members => {:only => [:id, :first_name, :last_name, :party, :url]}, :wards => {}}
    to_xml({:include => includes}.merge(options)) do |builder|
      builder<<active_committees.to_xml(:skip_instruct => true, :root => "committees", :only => [ :id, :title, :url ], :methods => [:openlylocal_url])
      builder<<meetings.forthcoming.to_xml(:skip_instruct => true, :root => "meetings", :methods => [:title, :formatted_date])
      builder<<recent_activity.to_xml(:skip_instruct => true, :root => "recent-activity")
    end
  end
  
end

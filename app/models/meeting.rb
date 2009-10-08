class Meeting < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :committee
  belongs_to :council
  has_one :minutes, :class_name => "Document", :as => "document_owner", :conditions => "document_type = 'Minutes'"
  has_one :agenda, :class_name => "Document", :as => "document_owner", :conditions => "document_type = 'Agenda'"
  has_many :documents, :as => "document_owner"
  validates_presence_of :date_held, :committee_id, :council_id
  validates_uniqueness_of :uid, :scope => :council_id, :allow_nil => true
  validates_uniqueness_of :url, :scope => :council_id, :if => Proc.new { |meeting| meeting.uid.blank? }, :message => "must be unique"
  validates_uniqueness_of :date_held, :scope => [:council_id, :committee_id]
  named_scope :forthcoming, lambda { { :conditions => ["date_held >= ?", Time.now], :order => "date_held" } }
  default_scope :order => "date_held"
  
  # alias attributes with names IcalUtilities wants to encode Vevents
  alias_attribute :summary, :title
  alias_attribute :dtstart, :date_held
  alias_attribute :location, :venue
  alias_attribute :created, :created_at
  alias_attribute :last_modified, :updated_at
  alias_method :old_to_xml, :to_xml

  def validate
    errors.add_to_base("either uid or url must be present") if uid.blank?&&url.blank?
  end

  # overwrite base find_existing so we can find by committee and url if uid is blank?
  def self.find_existing(params)
    params[:uid].blank? ? find_by_council_id_and_committee_id_and_url(params[:council_id], params[:committee_id], params[:url]) : 
      find_by_council_id_and_uid(params[:council_id], params[:uid])
  end

  def title
    "#{committee.title} meeting"
  end
  
  def extended_title
    "#{committee.title} meeting, #{date_held.to_s(:event_date)}"
  end
  
  def formatted_date
    date_held.to_s(:event_date).squish
  end
  
  def agenda_document_body=(doc_body=nil)
    create_document_body(doc_body, :agenda)
  end
  
  def minutes_document_body=(doc_body=nil)
    create_document_body(doc_body, :minutes)
  end
  
  # Formats the contact details in a way the IcalUtilities can use
  def organizer
    { :cn => committee.title, :uri => committee.url }
  end
  
  def event_uid
    "#{created_at.strftime("%Y%m%dT%H%M%S")}-meeting-#{id}@twfylocal"
  end
  
  def status
    date_held > Time.now ? "future" : "past"
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:methods => [:formatted_date, :openlylocal_url, :title] }.merge(options), &block)
  end
  
  private
  def create_document_body(doc_body=nil, type=nil)
    existing_record = send(type)
    existing_record ? existing_record.update_attributes(:raw_body => doc_body) : send("create_#{type}", {:raw_body => doc_body, :url => url, :document_type => type.to_s.capitalize})
  end
end

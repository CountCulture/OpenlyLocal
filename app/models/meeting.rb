class Meeting < ActiveRecord::Base
  include ScrapedModel
  belongs_to :committee
  belongs_to :council
  has_one :minutes, :class_name => "Document", :as => "document_owner", :conditions => "document_type = 'Minutes'"
  has_one :agenda, :class_name => "Document", :as => "document_owner", :conditions => "document_type = 'Agenda'"
  has_many :documents, :as => "document_owner"
  validates_presence_of :date_held, :committee_id, :uid, :council_id
  validates_uniqueness_of :uid, :scope => :council_id
  named_scope :forthcoming, lambda { { :conditions => ["date_held >= ?", Time.now], :order => "date_held" } }
  default_scope :order => "date_held"
  
  # alias attributes with names IcalUtilities wants to encode Vevents
  alias_attribute :summary, :title
  alias_attribute :dtstart, :date_held
  alias_attribute :location, :venue
  alias_attribute :created, :created_at
  alias_attribute :last_modified, :updated_at
  
  def title
    "#{committee.title} meeting"
  end
  
  def extended_title
    "#{committee.title} meeting, #{date_held.to_s(:event_date)}"
  end
  
  def agenda_document_body=(doc_body=nil)
    create_document_body(doc_body, :agenda)
    
    # agenda ? agenda.update_attributes(:raw_body => doc_body) : create_agenda(:raw_body => doc_body, :url => url, :document_type => "Agenda")
  end
  
  def minutes_document_body=(doc_body=nil)
    create_document_body(doc_body, :minutes)
    # minutes ? minutes.update_attributes(:raw_body => doc_body) : create_minutes(:raw_body => doc_body, :url => url, :document_type => "Minutes")
  end
  
  # Formats the contact details in a way the IcalUtilities can use
  def organizer
    { :cn => committee.title, :uri => committee.url }
  end
  
  def event_uid
    "#{created_at.strftime("%Y%m%dT%H%M%S")}-meeting-#{id}@twfylocal"
  end
  
  private
  def create_document_body(doc_body=nil, type=nil)
    existing_record = send(type)
    existing_record ? existing_record.update_attributes(:raw_body => doc_body) : send("create_#{type}", {:raw_body => doc_body, :url => url, :document_type => type.to_s.capitalize})
  end
end

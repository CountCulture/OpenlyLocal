class Meeting < ActiveRecord::Base
  include ScrapedModel
  belongs_to :committee
  belongs_to :council
  has_one :minutes, :class_name => "Document", :as => "document_owner"
  validates_presence_of :date_held, :committee_id, :uid, :council_id
  validates_uniqueness_of :uid, :scope => :council_id
  # alias attributes with names IcalUtilities wants to encode Vevents
  alias_attribute :summary, :title
  alias_attribute :dtstart, :date_held
  alias_attribute :location, :venue
  alias_attribute :created, :created_at
  alias_attribute :last_modified, :updated_at
  
  def title
    "#{committee.title} meeting, #{date_held.to_s(:event_date).squish}"
  end
  
  def minutes_body=(doc_body=nil)
    minutes ? minutes.update_attributes(:raw_body => doc_body, :document_type => "Minutes") : create_minutes(:raw_body => doc_body, :url => url, :document_type => "Minutes")
  end
  
  # Formats the contact details in a way the IcalUtilities can use
  def organizer
    { :cn => committee.title, :uri => committee.url }
  end
  
  def event_uid
    "#{created_at}-meeting-#{id}@twfylocal"
  end
end

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

  def title
    "#{committee.title} meeting"
  end
  
  # return date as plain date, not datetime if meeting is at midnight
  def date_held
    return unless dh=self[:date_held]&&self[:date_held].in_time_zone
    (dh.hour==0 && dh.min==0) ? dh.to_date : dh
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
  
  # overwrite base matches_params so we can find by committee and url if uid is blank?
  def matches_params(params={})
    params[:uid].blank? ? (self[:committee_id] == params[:committee_id] && self[:url]==params[:url]) : super
  end

  # Formats the contact details in a way the IcalUtilities can use
  def organizer
    { :cn => committee.title, :uri => committee.url }
  end
  
  def event_uid
    "#{created_at.strftime("%Y%m%dT%H%M%S")}-meeting-#{id}@twfylocal"
  end
  
  def status
    date_held.to_time > Time.now ? "future" : "past"
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:methods => [:formatted_date, :openlylocal_url, :title] }.merge(options), &block)
  end
  
  protected
  # overwrites standard orphan_records_callback (defined in ScrapedModel mixin) to delete meetings not yet happened
  def self.orphan_records_callback(recs=nil, options={})
    return if recs.blank? || !options[:save_results] # skip if no records or doing dry run
    recs.each{ |r| r.destroy if r.date_held > Time.now} #delete orphan meetings that have not yet happened
  end
  
  private
  def create_document_body(doc_body=nil, type=nil)
    existing_record = send(type)
    existing_record ? existing_record.update_attributes(:raw_body => doc_body) : send("create_#{type}", {:raw_body => doc_body, :url => url, :document_type => type.to_s.capitalize})
  end
end

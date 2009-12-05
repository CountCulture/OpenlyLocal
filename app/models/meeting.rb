class Meeting < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :committee
  belongs_to :council
  has_one :minutes, :class_name => "Document", :as => "document_owner", :conditions => "document_type = 'Minutes'"
  has_one :agenda, :class_name => "Document", :as => "document_owner", :conditions => "document_type = 'Agenda'"
  has_many :documents, :as => "document_owner"
  validates_presence_of :date_held, :committee_id, :council_id
  validates_uniqueness_of :uid, :scope => :council_id, :allow_nil => true
  validates_uniqueness_of :url, :scope => :council_id, :allow_nil => true, :if => Proc.new { |meeting| meeting.uid.blank? }, :message => "must be unique"
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

  # Overwrite existing find_all_existing from scraped_model so only return meetings with council_id and same committee_id from params
  def self.find_all_existing(params)
    raise ArgumentError, ":committee_id or :council_id is missing from submitted params" if params[:council_id].blank? || params[:committee_id].blank? 
    find_all_by_council_id_and_committee_id(params[:council_id], params[:committee_id])
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
  
  # overwrite base matches_params so we can find by committee and url or committee and date_held if uid is blank?
  def matches_params(params={})
    if params[:uid].blank?
      self[:committee_id] == params[:committee_id] && (self[:url]==params[:url] || self[:date_held]==params[:date_held])
    else
      super 
    end
  end

  # Formats the contact details in a way the IcalUtilities can use
  def organizer
    { :cn => committee.title, :uri => committee.url }
  end
  
  def event_uid
    "#{created_at.strftime("%Y%m%dT%H%M%S")}-meeting-#{id}@twfylocal"
  end
  
  def status
    return unless self[:date_held] || self[:status]
    st = []
    st << self[:status].downcase unless self[:status].blank?
    st << (self[:date_held] > Time.now ? "future" : "past") unless self[:date_held].blank?
    st.join(" ")
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:methods => [:formatted_date, :openlylocal_url, :title] }.merge(options), &block)
  end
  
  protected
  # overwrites standard orphan_records_callback (defined in ScrapedModel mixin) to delete meetings not yet happened
  def self.orphan_records_callback(recs=nil, options={})
    return if recs.blank? || !options[:save_results] # skip if no records or doing dry run
    recs.select{ |r| r[:date_held] > Time.now }.each do |r| # check vs attribute, not method, which turns into date if time is not known (i.e. midnight)
      r.destroy
      logger.debug { "Destroyed orphan record: #{r.inspect}" }
    end #delete orphan meetings that have not yet happened
  end
  
  private
  def create_document_body(doc_body=nil, type=nil)
    existing_record = send(type)
    existing_record ? existing_record.update_attributes(:raw_body => doc_body) : send("create_#{type}", {:raw_body => doc_body, :url => url, :document_type => type.to_s.capitalize})
  end
end

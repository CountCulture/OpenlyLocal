class Committee < ActiveRecord::Base
  include ScrapedModel::Base
  include PartyBreakdown
  validates_presence_of :title, :url, :uid, :council_id
  validates_uniqueness_of :title, :scope => :council_id
  belongs_to :council
  belongs_to :ward
  has_many :meetings
  has_many :meeting_documents, :through => :meetings, :source => :documents, :select => "documents.id, documents.title, documents.document_type, documents.document_owner_type, documents.document_owner_id, documents.created_at, documents.updated_at", :order => "meetings.date_held DESC"
  has_many :memberships, :primary_key => :uid
  has_many :members, :through => :memberships
  has_one :next_meeting, :class_name => "Meeting", :conditions => 'meetings.date_held > \'#{Time.now.to_s(:db)}\'', :order => 'date_held'
  allow_access_to :members, :via => :uid
  before_save :normalise_title

  named_scope :active, lambda { {
              :select => "committees.*, COUNT(meetings.id) AS meeting_count",
              :conditions => ["meetings.date_held > ?", 1.year.ago],
              :joins => "LEFT JOIN meetings ON meetings.committee_id = committees.id",
              :group => "committees.id",
              :order => "committees.title" } }
  
  named_scope :with_activity_status, lambda { {
              :select => "committees.*, (COUNT(meetings.id) > 0) AS active",
              :joins => "LEFT JOIN meetings ON meetings.committee_id = committees.id AND meetings.date_held > '#{1.year.ago.to_s(:db)}'",
              :group => "committees.id",
              :order => "committees.title" }}

  def status
    return unless respond_to?(:active?)
    active? ? "active" : "inactive"
  end

  private
  def normalise_title
    self.normalised_title = TitleNormaliser.normalise_title(title)
  end
end

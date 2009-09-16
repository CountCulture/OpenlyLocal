class Committee < ActiveRecord::Base
  include ScrapedModel
  include PartyBreakdown
  validates_presence_of :title, :url, :uid, :council_id
  validates_uniqueness_of :title, :scope => :council_id
  belongs_to :council
  belongs_to :ward
  has_many :meetings
  has_many :meeting_documents, :through => :meetings, :source => :documents, :select => "documents.id, documents.title, documents.document_type, documents.document_owner_type, documents.document_owner_id, documents.created_at, documents.updated_at", :order => "meetings.date_held DESC"
  has_many :memberships, :primary_key => :uid
  has_many :members, :through => :memberships, :extend => UidAssociationExtension
  delegate :uids, :to => :members, :prefix => "member"
  delegate :uids=, :to => :members, :prefix => "member"
end

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
  allow_access_to :members, :via => :uid
  before_save :normalise_title

  private
  def normalise_title
    self.normalised_title = TitleNormaliser.normalise_title(title)
  end
end

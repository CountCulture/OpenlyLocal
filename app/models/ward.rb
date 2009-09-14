class Ward < ActiveRecord::Base
  include ScrapedModel
  belongs_to :council
  has_many :members, :extend => UidAssociationExtension
  has_many :committees, :extend => UidAssociationExtension
  delegate :uids, :to => :members, :prefix => "member"
  delegate :uids=, :to => :members, :prefix => "member"
  delegate :uids, :to => :committees, :prefix => "committee"
  delegate :uids=, :to => :committees, :prefix => "committee"
  validates_presence_of :name, :council_id
  validates_uniqueness_of :name, :scope => :council_id
  alias_attribute :title, :name

  # override standard find_existing from ScrapedModel to find by council and name, not UID
  def self.find_existing(params)
    find_by_council_id_and_name(params[:council_id], clean_name(params[:name]))
  end
  
  def name=(raw_name)
    self[:name] = self.class.clean_name(raw_name)
  end
  
  private
  def self.clean_name(raw_name)
    raw_name.blank? ? raw_name : raw_name.sub(/ward\s*$/i, '').strip
  end
end

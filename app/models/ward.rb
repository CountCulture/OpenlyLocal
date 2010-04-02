class Ward < ActiveRecord::Base
  include ScrapedModel::Base
  include AreaStatisticMethods
  belongs_to :council
  belongs_to :police_team
  has_many :members
  has_many :committees
  has_many :meetings, :through => :committees
  has_many :datapoints, :as => :area
  has_many :dataset_topics, :through => :datapoints
  has_many :polls, :as => :area, :order => "date_held DESC"
  has_one  :boundary, :as => :area
  allow_access_to :members, :via => :uid
  allow_access_to :committees, :via => [:uid, :normalised_title]
  validates_presence_of :name, :council_id
  validates_uniqueness_of :name, :scope => :council_id
  alias_attribute :title, :name
  
  # Given a resource URI identifying the ward, returns the ward
  def self.find_from_resource_uri(resource_uri)
    case resource_uri
    when /statistics.data.gov.uk\/id\/local-authority-ward\/(\w+)/i
      find_by_snac_id($1)
    when /openlylocal.com\/id\/wards\/(\w+)/i
      find_by_id($1)
    end
  end

  # override standard matches_params from ScrapedModel to match against name if uid is blank
  def matches_params(params={})
    self[:name]==clean_name(params[:name]) || (!params[:uid].blank? && super )
  end

  def name=(raw_name)
    self[:name] = clean_name(raw_name)
  end

  def datapoints_for_topics(topic_ids=nil)
    return [] if topic_ids.blank? || ness_id.blank?
    dps = datapoints.all(:conditions => {:dataset_topic_id => topic_ids})
    if dps.empty?
      topic_uids = [DatasetTopic.find(topic_ids)].flatten.collect(&:ons_uid) # if only single topic is passed in, only single item will be returned. Turn into array on 1
      raw_datapoints = NessUtilities::RawClient.new('Tables', [['Areas', ness_id], ['Variables', topic_uids]]).process_and_extract_datapoints
      dps = raw_datapoints.collect do |rd|
        topic = DatasetTopic.find_by_ons_uid(rd[:ness_topic_id])
        datapoints.create!(:dataset_topic => topic, :value=>rd[:value])
      end
    end
    dps
  end
  
  # Returns all wards (including self) in council area
  def related
    council.wards
  end
  
  # DEPRECATED. Not actually used at the moment
  def siblings
    council.wards - [self]
  end

  private
  def clean_name(raw_name)
    raw_name.blank? ? raw_name : NameParser.strip_all_spaces(raw_name.sub(/\bward\s*$/i, ''))
  end
end

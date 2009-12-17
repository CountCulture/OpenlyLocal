class OnsDatapoint < ActiveRecord::Base
  validates_presence_of :value
  validates_presence_of :ons_dataset_topic_id
  validates_presence_of :ward_id
  belongs_to :ons_dataset_topic
  belongs_to :ward
#  default_scope :include => {:ons_dataset_topic => :ons_dataset_family}
  named_scope :with_topic_uids, lambda { |ons_uids| {:conditions => ["ons_datapoints.ons_dataset_topic_id = ons_dataset_topics.id AND ons_dataset_topics.ons_uid in (?)", ons_uids], :joins => "INNER JOIN ons_dataset_topics", :group => 'ons_datapoints.id'} }
  delegate :muid_format, :muid_type, :short_title, :to => :ons_dataset_topic

  def ons_dataset_family
    ons_dataset_topic.ons_dataset_family
  end

  def title
    ons_dataset_topic.title
  end

  def extended_title
    "#{ons_dataset_topic.title} (#{ward.name})"
  end

  def related_datapoints
    ons_dataset_topic.ons_datapoints.all(:conditions => {:ward_id => ward.siblings.collect(&:id)})
  end

end

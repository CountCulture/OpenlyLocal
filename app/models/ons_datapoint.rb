class OnsDatapoint < ActiveRecord::Base
  validates_presence_of :value
  validates_presence_of :ons_dataset_topic_id
  validates_presence_of :ward_id
  belongs_to :ons_dataset_topic
  belongs_to :ward
  default_scope :include => {:ons_dataset_topic => :ons_dataset_family}

  def ons_dataset_family
    ons_dataset_topic.ons_dataset_family
  end

  def title
    "#{ons_dataset_topic.title} (#{@ward.name})"
  end

  def value
    ons_dataset_topic.muid_format ? sprintf(ons_dataset_topic.muid_format, self[:value]) : self[:value]
  end
end

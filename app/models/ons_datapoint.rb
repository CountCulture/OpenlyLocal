class OnsDatapoint < ActiveRecord::Base
  # validates_presence_of :value
  validates_presence_of :ons_dataset_topic_id
  validates_presence_of :area_id
  validates_presence_of :area_type
  belongs_to :ons_dataset_topic
  belongs_to :area, :polymorphic => true
#  default_scope :include => {:ons_dataset_topic => :ons_dataset_family}
  named_scope :with_topic_uids, lambda { |ons_uids| {:conditions => ["ons_datapoints.ons_dataset_topic_id = ons_dataset_topics.id AND ons_dataset_topics.ons_uid in (?)", ons_uids], :joins => "INNER JOIN ons_dataset_topics", :group => 'ons_datapoints.id'} }
  named_scope :with_topic_grouping, { :conditions => "ons_datapoints.ons_dataset_topic_id = ons_dataset_topics.id AND ons_dataset_topics.dataset_topic_grouping_id IS NOT NULL", :joins => "INNER JOIN ons_dataset_topics", :group => 'ons_datapoints.id'}
  # named_scope :limited_to, :conditions => []
  delegate :muid_format, :muid_type, :ons_uid, :short_title, :to => :ons_dataset_topic
  
  def validate
    errors.add(:value, "can't be blank") if self[:value].blank?
  end

  def ons_dataset_family
    ons_dataset_topic.ons_dataset_family
  end

  def title
    ons_dataset_topic.title
  end

  def extended_title
    "#{ons_dataset_topic.title} (#{area.name})"
  end
  
  # returns all ancestors, furthest away first, to allow breadcrumbs to be built
  def parents
    [ons_dataset_family.statistical_dataset, ons_dataset_family, ons_dataset_topic]
  end

  def related_datapoints
    related_areas = area.related
    ons_dataset_topic.ons_datapoints.all(:conditions => {:area_type => area.class.to_s, :area_id => related_areas.collect(&:id)}).sort_by{ |dp| dp.area.title }
  end
  
  # Returns value coerced into appropriate format based on ons_dataset_topic#muid
  def value
    case muid_type
    when 'Percentage', 'Years'
      self[:value].to_f
    else
      self[:value].to_i
    end 
  end

end

class Datapoint < ActiveRecord::Base

  validates_presence_of :dataset_topic_id
  validates_presence_of :area_id
  validates_presence_of :area_type
  belongs_to :dataset_topic
  belongs_to :area, :polymorphic => true
#  default_scope :include => {:dataset_topic => :dataset_family}

  named_scope :with_topic_uids, lambda { |ons_uids| { :conditions => ['dataset_topics.ons_uid IN (?)', ons_uids],
                                                      :joins => :dataset_topics,
                                                      :group => 'datapoints.id, datapoints.value, datapoints.dataset_topic_id, datapoints.area_id, datapoints.created_at, datapoints.updated_at, datapoints.area_type, datapoints.data_period_id'} }

  named_scope :with_topic_grouping, { :conditions => "dataset_topics.dataset_topic_grouping_id IS NOT NULL",
                                      :joins => :dataset_topics,
                                      :group => 'datapoints.id, datapoints.value, datapoints.dataset_topic_id, datapoints.area_id, datapoints.created_at, datapoints.updated_at, datapoints.area_type, datapoints.data_period_id'}

  named_scope :in_dataset, lambda { |dataset| { :conditions => ['dataset_topics.dataset_family_id IN (?)', dataset.dataset_families.collect(&:id)],
                                                :joins => :dataset_topics,
                                                :group => 'datapoints.id, datapoints.value, datapoints.dataset_topic_id, datapoints.area_id, datapoints.created_at, datapoints.updated_at, datapoints.area_type, datapoints.data_period_id' } }

  delegate :muid_format, :muid_type, :ons_uid, :short_title, :to => :dataset_topic
  alias_attribute :subject, :dataset_topic
  
  def validate
    errors.add(:value, "can't be blank") if self[:value].blank? # validations test after typecasting so we have to test in this way
  end

  def dataset_family
    dataset_topic.dataset_family
  end

  def title
    dataset_topic.title
  end

  def extended_title
    "#{dataset_topic.title} (#{area.name})"
  end
  
  # returns all ancestors, furthest away first, to allow breadcrumbs to be built
  def parents
    [dataset_family.dataset, dataset_family, dataset_topic]
  end

  def related_datapoints
    related_areas = area.related
    dataset_topic.datapoints.all(:conditions => {:area_type => area.class.to_s, :area_id => related_areas.collect(&:id)}).sort_by{ |dp| dp.area.title }
  end
  
  # Returns value coerced into appropriate format based on dataset_topic#muid
  def value
    case muid_type
    when 'Percentage', 'Years'
      self[:value].to_f
    when 'Yes/No'
      self[:value].to_i == 1 ? 'Yes' : 'No'
    else
      self[:value].to_i
    end 
  end

end

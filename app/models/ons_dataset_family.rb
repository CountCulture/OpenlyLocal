class OnsDatasetFamily < ActiveRecord::Base
  has_and_belongs_to_many :ons_subjects
  has_many :ons_datasets
  has_many :ons_dataset_topics
  has_many :ons_datapoints, :through => :ons_dataset_topics
  validates_presence_of :title
  validates_presence_of :source_type

end

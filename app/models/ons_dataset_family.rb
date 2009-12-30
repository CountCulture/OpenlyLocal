class OnsDatasetFamily < ActiveRecord::Base
  has_and_belongs_to_many :ons_subjects
  has_many :ons_datasets
  has_many :ons_dataset_topics
  has_many :ons_datapoints, :through => :ons_dataset_topics
  belongs_to :statistical_dataset
  validates_presence_of :title
  validates_presence_of :source_type
  validates_presence_of :statistical_dataset_id

  def parents
    [statistical_dataset]
  end

end

class DatasetTopicGrouping < ActiveRecord::Base
  DisplayOptions = %w(graph in_words)
  has_many :dataset_topics
  has_many :datasets
  validates_presence_of :title
end

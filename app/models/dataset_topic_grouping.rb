class DatasetTopicGrouping < ActiveRecord::Base
  DisplayOptions = %w(graph in_words)
  has_many :ons_dataset_topics
  validates_presence_of :title
end

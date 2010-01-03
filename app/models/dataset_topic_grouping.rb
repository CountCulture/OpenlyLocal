class DatasetTopicGrouping < ActiveRecord::Base
  DisplayOptions = %w(graph in_words)
  has_many :dataset_topics
  validates_presence_of :title
end

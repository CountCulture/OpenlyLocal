class AddDatasetTopicGroupingIdToDatasets < ActiveRecord::Migration
  def self.up
    add_column :datasets, :dataset_topic_grouping_id, :integer
  end

  def self.down
    remove_column :datasets, :dataset_topic_grouping_id
  end
end

class AddSortOrderToDatasetTopicGroupings < ActiveRecord::Migration
  def self.up
    add_column :dataset_topic_groupings, :sort_by, :string
  end

  def self.down
    remove_column :dataset_topic_groupings, :sort_by
  end
end

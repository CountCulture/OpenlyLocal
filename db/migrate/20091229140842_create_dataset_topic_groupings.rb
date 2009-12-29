class CreateDatasetTopicGroupings < ActiveRecord::Migration
  def self.up
    create_table :dataset_topic_groupings do |t|
      t.string  :title
      t.string  :display_as
      t.timestamps
    end
    add_column :ons_dataset_topics, :dataset_topic_grouping_id, :integer
  end

  def self.down
    remove_column :ons_dataset_topics, :dataset_topic_grouping_id
    drop_table :dataset_topic_groupings
  end
end

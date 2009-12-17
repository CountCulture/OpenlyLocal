class AddShortTitleToOnsDatasetTopic < ActiveRecord::Migration
  def self.up
    add_column :ons_dataset_topics, :short_title, :string
  end

  def self.down
    remove_column :ons_dataset_topics, :short_title
  end
end

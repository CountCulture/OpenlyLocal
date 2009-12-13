class AddDescriptionToOnsTopics < ActiveRecord::Migration
  def self.up
    add_column :ons_dataset_topics, :description, :text
    add_column :ons_dataset_topics, :data_date, :date
  end

  def self.down
    remove_column :ons_dataset_topics, :description
    remove_column :ons_dataset_topics, :data_date
  end
end

class AddMuidToOnsTopics < ActiveRecord::Migration
  def self.up
    add_column :ons_dataset_topics, :muid, :integer
  end

  def self.down
    remove_column :ons_dataset_topics, :muid
  end
end

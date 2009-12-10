class CreateOnsDatasetTopics < ActiveRecord::Migration
  def self.up
    create_table :ons_dataset_topics do |t|
      t.string :title
      t.integer :ons_uid
      t.integer :ons_dataset_family_id
      t.timestamps
    end
  end

  def self.down
    drop_table :ons_dataset_topics
  end
end

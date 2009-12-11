class CreateOnsDatapoints < ActiveRecord::Migration
  def self.up
    create_table :ons_datapoints do |t|
      t.string :value
      t.integer :ons_dataset_topic_id
      t.integer :ward_id
      t.timestamps
    end
  end

  def self.down
    drop_table :ons_datapoints
  end
end

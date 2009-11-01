class CreateOnsDatasets < ActiveRecord::Migration
  def self.up
    create_table :ons_datasets do |t|
      t.string :title
      t.integer :ds_family_id
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end

  def self.down
    drop_table :ons_datasets
  end
end

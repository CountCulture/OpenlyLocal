class CreateStatisticalDatasets < ActiveRecord::Migration
  def self.up
    create_table :statistical_datasets do |t|
      t.string    :title
      t.text      :description
      t.string    :url
      t.string    :originator
      t.string    :originator_url
      t.timestamps
    end
    add_column :ons_dataset_families, :statistical_dataset_id, :integer
  end

  def self.down
    remove_column :ons_dataset_families, :statistical_dataset_id
    drop_table :statistical_datasets
  end
end

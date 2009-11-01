class CreateOnsDatasetSamples < ActiveRecord::Migration
  def self.up
    rename_table :ons_datasets, :ons_dataset_families
    remove_column :ons_dataset_families, :end_date
    remove_column :ons_dataset_families, :start_date
    create_table :ons_datasets do |t|
      t.date  :start_date
      t.date  :end_date
      t.integer :ons_dataset_family_id
      t.timestamps
    end
    create_table :ons_dataset_families_ons_subjects, :force => true, :id => false do |t|
      t.integer :ons_subject_id
      t.integer :ons_dataset_family_id
    end
  end

  def self.down
    drop_table :ons_dataset_families_ons_subjects
    drop_table :ons_datasets
    add_column :ons_dataset_families, :start_date, :date
    add_column :ons_dataset_families, :end_date, :date
    rename_table :ons_dataset_families, :ons_datasets
  end
end

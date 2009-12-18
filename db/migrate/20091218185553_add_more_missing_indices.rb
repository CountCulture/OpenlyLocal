class AddMoreMissingIndices < ActiveRecord::Migration
  def self.up
    add_index :cached_postcodes, :output_area_id
    add_index :ons_datapoints, :ward_id
    add_index :ons_datapoints, :ons_dataset_topic_id
    add_index :ons_dataset_topics, :ons_dataset_family_id
    add_index :ons_datasets, :ons_dataset_family_id
    add_index :ons_dataset_families_ons_subjects, [:ons_subject_id, :ons_dataset_family_id], :name => "ons_families_subjects_join_index"
    add_index :ons_dataset_families_ons_subjects, [:ons_dataset_family_id, :ons_subject_id], :name => "ons_subjects_families_join_index"
    add_index :output_areas, :ward_id
  end

  def self.down
    remove_index :cached_postcodes, :output_area_id
    remove_index :ons_datapoints, :ward_id
    remove_index :ons_datapoints, :ons_dataset_topic_id
    remove_index :ons_dataset_topics, :ons_dataset_family_id
    remove_index :ons_datasets, :ons_dataset_family_id
    remove_index :ons_dataset_families_ons_subjects, :column => [:ons_subject_id, :ons_dataset_family_id], :name => "ons_families_subjects_join_index"
    remove_index :ons_dataset_families_ons_subjects, :column => [:ons_dataset_family_id, :ons_subject_id], :name => "ons_subjects_families_join_index"
    remove_index :output_areas, :ward_id
  end
end

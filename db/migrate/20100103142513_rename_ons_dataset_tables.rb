class RenameOnsDatasetTables < ActiveRecord::Migration
  def self.up
    rename_table :ons_dataset_topics, :dataset_topics
    rename_table :ons_dataset_families, :dataset_families
    rename_table :datasets, :old_datasets
    rename_table :datapoints, :old_datapoints
    rename_table :ons_datapoints, :datapoints
    rename_table :statistical_datasets, :datasets
    rename_column :old_datapoints, :dataset_id, :old_dataset_id
    rename_column :datapoints, :ons_dataset_topic_id, :dataset_topic_id
    rename_column :dataset_topics, :ons_dataset_family_id, :dataset_family_id
    rename_column :ons_datasets, :ons_dataset_family_id, :dataset_family_id
    rename_table :ons_dataset_families_ons_subjects, :dataset_families_ons_subjects
    rename_column :dataset_families_ons_subjects, :ons_dataset_family_id, :dataset_family_id
    rename_column :dataset_families, :statistical_dataset_id, :dataset_id
  end

  def self.down
    rename_column :dataset_families, :dataset_id, :statistical_dataset_id
    rename_column :dataset_families_ons_subjects, :dataset_family_id, :ons_dataset_family_id
    rename_table :dataset_families_ons_subjects, :ons_dataset_families_ons_subjects
    rename_column :ons_datasets, :dataset_family_id, :ons_dataset_family_id
    rename_column :dataset_topics, :dataset_family_id, :ons_dataset_family_id
    rename_column :datapoints, :dataset_topic_id, :ons_dataset_topic_id
    rename_column :old_datapoints, :old_dataset_id, :dataset_id
    rename_table :datasets, :statistical_datasets
    rename_table :datapoints, :ons_datapoints
    rename_table :old_datapoints, :datapoints
    rename_table :old_datasets, :datasets
    rename_table :dataset_families, :ons_dataset_families
    rename_table :dataset_topics, :ons_dataset_topics
  end
end

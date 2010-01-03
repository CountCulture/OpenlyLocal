class AddMoreDatasetIndices < ActiveRecord::Migration
  def self.up    
    add_index :dataset_families, :dataset_id
    add_index :dataset_topics, :dataset_topic_grouping_id
    add_index :police_authorities, :police_force_id
    add_index :hyperlocal_sites, :hyperlocal_group_id
    add_index :datapoints, [:area_id, :area_type]
    remove_index :datapoints, :name => :index_ons_datapoints_on_ward_id
  end
  
  def self.down
    remove_index :dataset_families, :dataset_id
    remove_index :dataset_topics, :dataset_topic_grouping_id
    remove_index :police_authorities, :police_force_id
    remove_index :hyperlocal_sites, :hyperlocal_group_id
    remove_index :datapoints, :column => [:area_id, :area_type]
  end
end

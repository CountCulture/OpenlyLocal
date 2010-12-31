class DestroyOldDatasetAndOldDatapointTables < ActiveRecord::Migration
  def self.up
    drop_table :old_datasets
    drop_table :old_datapoints
  end

  def self.down
  end
end

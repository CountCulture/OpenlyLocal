class ConvertHyperlocalDistanceColumnToDistanceCovered < ActiveRecord::Migration
  def self.up
    rename_column :hyperlocal_sites, :distance, :distance_covered
    remove_column :councils, :distance
  end

  def self.down
    add_column :councils, :distance, :float
    rename_column :hyperlocal_sites, :distance_covered, :distance
  end
end

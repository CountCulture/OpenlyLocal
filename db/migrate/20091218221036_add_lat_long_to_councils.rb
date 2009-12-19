class AddLatLongToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :lat, :float
    add_column :councils, :lng, :float
    add_column :councils, :distance, :float
  end

  def self.down
    remove_column :councils, :distance
    remove_column :councils, :lng
    remove_column :councils, :lat
  end
end

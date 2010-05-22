class AddCrimeAreaId < ActiveRecord::Migration
  def self.up
    add_column :wards, :crime_area_id, :integer
  end

  def self.down
    remove_column :wards, :crime_area_id
  end
end

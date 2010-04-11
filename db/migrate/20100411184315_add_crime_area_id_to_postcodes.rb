class AddCrimeAreaIdToPostcodes < ActiveRecord::Migration
  def self.up
    add_column :postcodes, :crime_area_id, :integer
  end

  def self.down
    remove_column :postcodes, :crime_area_id
  end
end

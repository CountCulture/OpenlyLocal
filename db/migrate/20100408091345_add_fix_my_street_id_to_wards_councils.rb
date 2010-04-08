class AddFixMyStreetIdToWardsCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :fix_my_street_id, :string
    add_column :wards, :fix_my_street_id, :string
  end

  def self.down
    remove_column :wards, :fix_my_street_id
    remove_column :councils, :fix_my_street_id
  end
end

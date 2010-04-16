class RemoveFixMyStreetIds < ActiveRecord::Migration
  def self.up
    remove_column :councils, :fix_my_street_id
    remove_column :wards, :fix_my_street_id
  end

  def self.down
    add_column :wards, :fix_my_street_id, :string
    add_column :councils, :fix_my_street_id, :string
  end
end

class AddOsIdToCouncilsAndWards < ActiveRecord::Migration
  def self.up
    add_column :councils, :os_id, :string
    add_column :wards, :os_id, :string
  end

  def self.down
    remove_column :wards, :os_id
    remove_column :councils, :os_id
  end
end

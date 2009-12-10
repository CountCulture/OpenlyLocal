class AddNessIdsToCouncilsWards < ActiveRecord::Migration
  def self.up
    add_column :councils, :ness_id, :string
    add_column :wards, :ness_id, :string
  end

  def self.down
    remove_column :councils, :ness_id
    remove_column :wards, :ness_id
  end
end

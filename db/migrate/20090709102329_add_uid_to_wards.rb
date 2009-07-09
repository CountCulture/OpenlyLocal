class AddUidToWards < ActiveRecord::Migration
  def self.up
    add_column :wards, :uid, :integer
  end

  def self.down
    remove_column :wards, :uid
  end
end

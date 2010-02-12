class ConvertWardUidToString < ActiveRecord::Migration
  def self.up
    change_column :wards, :uid, :string
  end

  def self.down
    change_column :wards, :uid, :integer
  end
end

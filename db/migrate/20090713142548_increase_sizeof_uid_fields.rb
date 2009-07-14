class IncreaseSizeofUidFields < ActiveRecord::Migration
  def self.up
    change_column :members, :uid, :integer, :limit => 8
    change_column :committees, :uid, :integer, :limit => 8
    change_column :meetings, :uid, :integer, :limit => 8
  end

  def self.down
    change_column :meetings, :uid, :integer
    change_column :committees, :uid, :integer
    change_column :members, :uid, :integer
  end
end

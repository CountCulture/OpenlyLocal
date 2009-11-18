class ConvertMemberUidsToStrings < ActiveRecord::Migration
  def self.up
    change_column :members, :uid, :string
    change_column :meetings, :uid, :string
  end

  def self.down
    change_column :meetings, :uid, :integer
    change_column :members, :uid, :integer
  end
end

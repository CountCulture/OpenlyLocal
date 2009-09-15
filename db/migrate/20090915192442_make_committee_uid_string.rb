class MakeCommitteeUidString < ActiveRecord::Migration
  def self.up
    change_column :committees, :uid, :string
  end

  def self.down
    change_column :committees, :uid, :integer
  end
end

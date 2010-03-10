class AddMemberIdToCandidates < ActiveRecord::Migration
  def self.up
    add_column :candidates, :member_id, :integer
  end

  def self.down
    remove_column :candidates, :member_id
  end
end

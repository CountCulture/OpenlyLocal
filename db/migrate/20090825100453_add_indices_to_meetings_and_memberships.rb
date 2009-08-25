class AddIndicesToMeetingsAndMemberships < ActiveRecord::Migration
  def self.up
    add_index :meetings, :committee_id
    add_index :memberships, [:committee_id, :member_id]
  end

  def self.down
    remove_index :memberships, [:committee_id, :member_id]
    remove_index :meetings, :committee_id
  end
end

class AddStatusToMeetings < ActiveRecord::Migration
  def self.up
    add_column :meetings, :status, :string
  end

  def self.down
    remove_column :meetings, :status
  end
end

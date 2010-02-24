class AddApprovedFlagToUserSubmissions < ActiveRecord::Migration
  def self.up
    add_column :user_submissions, :approved, :boolean, :default => false
  end

  def self.down
    remove_column :user_submissions, :approved
  end
end

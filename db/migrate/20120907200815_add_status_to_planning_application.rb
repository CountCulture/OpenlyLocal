class AddStatusToPlanningApplication < ActiveRecord::Migration
  def self.up
    add_column :planning_applications, :status, :string
  end

  def self.down
    remove_column :planning_applications, :status
  end
end

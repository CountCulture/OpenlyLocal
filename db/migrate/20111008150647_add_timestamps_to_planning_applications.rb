class AddTimestampsToPlanningApplications < ActiveRecord::Migration
  def self.up
    add_column :planning_applications, :created_at, :datetime
    add_column :planning_applications, :updated_at, :datetime
    PlanningApplication.reset_column_information
    PlanningApplication.update_all :created_at => 4.months.ago, :updated_at => 4.months.ago
  end

  def self.down
    remove_column :planning_applications, :updated_at
    remove_column :planning_applications, :created_at
  end
end

class ChangeColumnsToTextOnPlanningApplications < ActiveRecord::Migration
  def self.up
    change_column :planning_applications, :status, :text
    change_column :planning_applications, :applicant_name, :text
  end

  def self.down
    change_column :planning_applications, :status, :string
    change_column :planning_applications, :applicant_name, :string, :limit => 1024
  end
end

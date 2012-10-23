class ChangeDecisionToTextOnPlanningApplications < ActiveRecord::Migration
  def self.up
    change_column :planning_applications, :decision, :text
  end

  def self.down
    change_column :planning_applications, :decision, :string, :limit => 1024
  end
end

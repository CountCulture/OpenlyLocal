class RemoveLimitsFromPlanningApplications < ActiveRecord::Migration
  def self.up
    change_column :planning_applications, :postcode, :string, :limit => nil
    change_column :planning_applications, :decision, :string, :limit => nil
    change_column :planning_applications, :application_type, :string, :limit => nil
  end

  def self.down
    change_column :planning_applications, :postcode, :string, :limit => 10
    change_column :planning_applications, :decision, :string, :limit => 64
    change_column :planning_applications, :application_type, :string, :limit => 64
  end
end

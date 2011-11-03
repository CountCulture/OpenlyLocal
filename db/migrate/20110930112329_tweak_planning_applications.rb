class TweakPlanningApplications < ActiveRecord::Migration
  def self.up
    change_column :planning_applications, :date_scraped, :datetime
    change_column :planning_applications, :other_attributes, :text, :limit => 65537
  end

  def self.down
  end
end

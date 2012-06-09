class RemovePlanningApplicationAddressRequirement < ActiveRecord::Migration
  def self.up
    change_column :planning_applications, :address, :text, :null => true
  end

  def self.down
    change_column :planning_applications, :address, :text, :null => false
  end
end

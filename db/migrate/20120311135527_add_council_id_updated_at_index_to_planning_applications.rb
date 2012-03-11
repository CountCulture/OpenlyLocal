class AddCouncilIdUpdatedAtIndexToPlanningApplications < ActiveRecord::Migration
  def self.up
    add_index :planning_applications, [:council_id, :updated_at]
  end

  def self.down
    remove_index :planning_applications, :column => [:council_id, :updated_at]
  end
end

class AddCouncilIdAndStartDateIndexForPlanning < ActiveRecord::Migration
  def self.up
    add_index :planning_applications, [:council_id, :start_date]
  end

  def self.down
    remove_index :planning_applications, [:council_id, :start_date]
  end
end

class RenameDateReceivedToStartDate < ActiveRecord::Migration
  def self.up
    rename_column :planning_applications, :date_received, :start_date
  end

  def self.down
    rename_column :planning_applications, :start_date, :date_received
  end
end

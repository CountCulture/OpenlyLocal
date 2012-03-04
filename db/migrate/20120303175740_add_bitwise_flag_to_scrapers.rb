class AddBitwiseFlagToScrapers < ActiveRecord::Migration
  def self.up
    add_column :planning_applications, :bitwise_flag, :integer, :limit => 1, :default => 0
  end

  def self.down
    remove_column :planning_applications, :bitwise_flag
  end
end

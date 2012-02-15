class AddApplicationType < ActiveRecord::Migration
  def self.up
    add_column :planning_applications, :application_type, :string, :limit => 64
  end

  def self.down
    remove_column :planning_applications, :application_type
  end
end

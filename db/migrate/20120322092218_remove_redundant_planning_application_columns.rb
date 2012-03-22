class RemoveRedundantPlanningApplicationColumns < ActiveRecord::Migration
  def self.up
    remove_column :planning_applications, :on_notice_from
    remove_column :planning_applications, :on_notice_to
    remove_column :planning_applications, :info_tinyurl
    remove_column :planning_applications, :comment_tinyurl
    remove_column :planning_applications, :map_url
  end

  def self.down
    add_column :planning_applications, :map_url, :string,           :limit => 150
    add_column :planning_applications, :comment_tinyurl, :string,   :limit => 50
    add_column :planning_applications, :info_tinyurl, :string,      :limit => 50
    add_column :planning_applications, :on_notice_to, :date
    add_column :planning_applications, :on_notice_from, :date
  end
end

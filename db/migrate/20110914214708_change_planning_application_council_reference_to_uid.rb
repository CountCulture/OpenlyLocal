class ChangePlanningApplicationCouncilReferenceToUid < ActiveRecord::Migration
  def self.up
    rename_column :planning_applications, :council_reference, :uid
    add_column :planning_applications, :on_notice_from, :date
    add_column :planning_applications, :on_notice_to, :date
    add_column :planning_applications, :decision, :string, :limit => 64
    add_column :planning_applications, :other_attributes, :text
  end

  def self.down
    remove_column :planning_applications, :other_attributes
    remove_column :planning_applications, :decision
    remove_column :planning_applications, :on_notice_to
    remove_column :planning_applications, :on_notice_from
    rename_column :planning_applications, :uid, :council_reference
  end
end

class AddActiveFlagToPoliceOfficers < ActiveRecord::Migration
  def self.up
    add_column :police_officers, :active, :boolean, :default => true
  end

  def self.down
    remove_column :police_officers, :active
  end
end

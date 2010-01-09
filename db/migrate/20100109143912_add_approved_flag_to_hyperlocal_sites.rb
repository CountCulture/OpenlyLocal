class AddApprovedFlagToHyperlocalSites < ActiveRecord::Migration
  def self.up
    add_column :hyperlocal_sites, :approved, :boolean
  end

  def self.down
    remove_column :hyperlocal_sites, :approved
  end
end

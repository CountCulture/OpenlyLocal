class AddDescriptionToHyperLocalSites < ActiveRecord::Migration
  def self.up
    add_column :hyperlocal_sites, :description, :text
  end

  def self.down
    remove_column :hyperlocal_sites, :description
  end
end

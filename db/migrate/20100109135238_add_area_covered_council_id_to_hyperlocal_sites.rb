class AddAreaCoveredCouncilIdToHyperlocalSites < ActiveRecord::Migration
  def self.up
    add_column :hyperlocal_sites, :area_covered, :string
    add_column :hyperlocal_sites, :council_id, :integer
    add_column :hyperlocal_sites, :country, :string
  end

  def self.down
    remove_column :hyperlocal_sites, :country
    remove_column :hyperlocal_sites, :council_id
    remove_column :hyperlocal_sites, :area_covered
  end
end

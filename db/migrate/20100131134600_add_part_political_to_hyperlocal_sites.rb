class AddPartPoliticalToHyperlocalSites < ActiveRecord::Migration
  def self.up
    add_column :hyperlocal_sites, :party_affiliation, :string
  end

  def self.down
    remove_column :hyperlocal_sites, :party_affiliation
  end
end

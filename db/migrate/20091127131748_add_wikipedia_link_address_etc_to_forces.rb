class AddWikipediaLinkAddressEtcToForces < ActiveRecord::Migration
  def self.up
    add_column :police_forces, :wikipedia_url, :string
    add_column :police_forces, :telephone, :string
    add_column :police_forces, :address, :text
    rename_column :councils, :police_neighbourhood_url, :police_force_url
  end

  def self.down
    remove_column :police_forces, :address
    remove_column :police_forces, :telephone
    rename_column :councils, :police_force_url, :police_neighbourhood_url
    remove_column :police_forces, :wikipedia_url
  end
end

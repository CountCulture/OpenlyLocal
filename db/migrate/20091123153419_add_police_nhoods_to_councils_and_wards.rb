class AddPoliceNhoodsToCouncilsAndWards < ActiveRecord::Migration
  def self.up
    add_column :councils, :police_neighbourhood_url, :string
    add_column :wards, :police_neighbourhood_url, :string
  end

  def self.down
    remove_column :wards, :police_neighbourhood_url
    remove_column :councils, :police_neighbourhood_url
  end
end

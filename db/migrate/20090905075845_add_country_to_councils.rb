class AddCountryToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :country, :string
  end

  def self.down
    remove_column :councils, :country
  end
end

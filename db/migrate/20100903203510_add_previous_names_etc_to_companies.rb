class AddPreviousNamesEtcToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :previous_names, :text
    add_column :companies, :sic_codes, :text
    add_column :companies, :country, :string
  end

  def self.down
    # remove_column :companies, :country
    remove_column :companies, :sic_codes
    remove_column :companies, :previous_names
  end
end

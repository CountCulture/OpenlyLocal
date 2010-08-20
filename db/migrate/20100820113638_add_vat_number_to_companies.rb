class AddVatNumberToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :vat_number, :string
  end

  def self.down
    remove_column :companies, :vat_number
  end
end

class AddCompanyIdToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :normalised_company_number, :string
    add_index :charities, :normalised_company_number
  end

  def self.down
    remove_index :charities, :company_id
    remove_column :charities, :company_id
    remove_index :charities, :company_number
  end
end
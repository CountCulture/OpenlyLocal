class AddExtraCompanyAttributes < ActiveRecord::Migration
  def self.up
    add_column :companies, :incorporation_date, :date
    add_column :companies, :company_type, :string
    add_column :companies, :wikipedia_url, :string
    add_column :companies, :status, :string
  end

  def self.down
    remove_column :companies, :status
    remove_column :companies, :wikipedia_url
    remove_column :companies, :company_type
    remove_column :companies, :incorporation_date
  end
end

class AddAccountsFieldsToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :contact_name , :string
    add_column :charities, :accounts_date, :date
    add_column :charities, :spending, :integer
    add_column :charities, :income, :integer
  end           
                
  def self.down
    remove_column :charities, :income
    remove_column :charities, :spending
    remove_column :charities, :accounts_date
    remove_column :charities, :contact_name 
  end
end

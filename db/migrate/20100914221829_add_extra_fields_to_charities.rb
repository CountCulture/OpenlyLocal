class AddExtraFieldsToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :employees, :integer
    add_column :charities, :accounts, :text
    add_column :charities, :financial_breakdown, :text
    add_column :charities, :trustees, :text
    add_column :charities, :other_names, :string
    add_column :charities, :volunteers, :integer
  end

  def self.down
    # remove_column :charities, :volunteers
    remove_column :charities, :other_names
    remove_column :charities, :trustees
    remove_column :charities, :financial_breakdown
    remove_column :charities, :accounts
    remove_column :charities, :employees
  end
end

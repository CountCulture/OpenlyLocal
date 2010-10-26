class AddFieldsToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :company_number, :string
    add_column :charities, :housing_association_number, :string
    add_column :charities, :fax, :string
    add_column :charities, :subsidiary_number, :integer
    add_column :charities, :area_of_benefit, :string
  end

  def self.down
    remove_column :charities, :area_of_benefit
    remove_column :charities, :subsidiary_number
    remove_column :charities, :fax
    remove_column :charities, :housing_association_number
    remove_column :charities, :company_number
  end
end

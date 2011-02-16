class AddCompanyNumberIndexToCharities < ActiveRecord::Migration
  def self.up
    add_index :charities, :company_number
  end

  def self.down
    remove_index :charities, :company_number
  end
end
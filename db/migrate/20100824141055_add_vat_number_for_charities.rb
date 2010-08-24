class AddVatNumberForCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :vat_number, :string
  end

  def self.down
    remove_column :charities, :vat_number
  end
end

class AddVatNumberToPoliceAuthorities < ActiveRecord::Migration
  def self.up
    add_column :police_authorities, :vat_number, :string
  end

  def self.down
    remove_column :police_authorities, :vat_number
  end
end

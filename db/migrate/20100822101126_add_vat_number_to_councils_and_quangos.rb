class AddVatNumberToCouncilsAndQuangos < ActiveRecord::Migration
  def self.up
    add_column :councils, :vat_number, :string
    add_column :quangos, :vat_number, :string
  end

  def self.down
    remove_column :quangos, :vat_number
    remove_column :councils, :vat_number
  end
end

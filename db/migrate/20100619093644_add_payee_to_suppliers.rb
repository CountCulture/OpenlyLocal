class AddPayeeToSuppliers < ActiveRecord::Migration
  def self.up
    add_column :suppliers, :payee_type, :string
    rename_column :suppliers, :company_id, :payee_id
    Supplier.update_all("payee_type = 'Company'")
  end

  def self.down
    rename_column :suppliers, :payee_id
    remove_column :suppliers, :payee_type
  end
end

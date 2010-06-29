class RenameSupplierCompanyNumberFailedPayeeSearch < ActiveRecord::Migration
  def self.up
    rename_column :suppliers, :company_number, :failed_payee_search
  end

  def self.down
    rename_column :suppliers, :failed_payee_search, :company_number
  end
end

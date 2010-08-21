class MakeFailedSupplierSearchBoolean < ActiveRecord::Migration
  def self.up
    change_column :suppliers, :failed_payee_search, :boolean
  end

  def self.down
    change_column :suppliers, :failed_payee_search, :string
  end
end

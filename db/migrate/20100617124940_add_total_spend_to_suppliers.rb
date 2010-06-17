class AddTotalSpendToSuppliers < ActiveRecord::Migration
  def self.up
    add_column :suppliers, :total_spend, :double
    add_column :suppliers, :recent_spend, :double
  end

  def self.down
    remove_column :suppliers, :recent_spend
    remove_column :suppliers, :total_spend
  end
end

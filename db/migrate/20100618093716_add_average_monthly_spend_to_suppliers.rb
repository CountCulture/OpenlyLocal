class AddAverageMonthlySpendToSuppliers < ActiveRecord::Migration
  def self.up
    rename_column :suppliers, :recent_spend, :average_monthly_spend
  end

  def self.down
    rename_column :suppliers, :average_monthly_spend, :recent_spend
  end
end

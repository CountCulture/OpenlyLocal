class RemoveSpendingStatsFromSupplier < ActiveRecord::Migration
  def self.up
    remove_column :suppliers, :total_spend
    remove_column :suppliers, :average_monthly_spend
  end

  def self.down
    add_column :suppliers, :average_monthly_spend, :float
    add_column :suppliers, :total_spend, :float
  end
end

class AddSpendingStatTransactionCount < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :transaction_count, :integer, :limit => 8
  end

  def self.down
    remove_column :spending_stats, :transaction_count
  end
end
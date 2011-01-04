class AddEarliestLatestTransactionToSpendingStats < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :earliest_transaction, :date
    add_column :spending_stats, :latest_transaction, :date
  end

  def self.down
    remove_column :spending_stats, :latest_transaction
    remove_column :spending_stats, :earliest_transaction
  end
end
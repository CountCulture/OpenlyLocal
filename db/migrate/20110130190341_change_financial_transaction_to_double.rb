class ChangeFinancialTransactionToDouble < ActiveRecord::Migration
  def self.up
    change_column :financial_transactions, :value, :double
  end

  def self.down
    change_column :financial_transactions, :value, :float
  end
end
class AddClassificationIdToFinancialTransactions < ActiveRecord::Migration
  def self.up
    add_column :financial_transactions, :classification_id, :integer
  end

  def self.down
    remove_column :financial_transactions, :classification_id
  end
end

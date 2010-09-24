class AddFinancialsIndices < ActiveRecord::Migration
  def self.up
    add_index :financial_transactions, :value
    add_index :financial_transactions, :date
    add_index :charities, :date_registered
  end

  def self.down
    remove_index :charities, :date_registered
    remove_index :financial_transactions, :date
    remove_index :financial_transactions, :value
  end
end

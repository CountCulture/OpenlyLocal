class AddFinancialTransactionInvoiceDate < ActiveRecord::Migration
  def self.up
    add_column :financial_transactions, :invoice_date, :date
  end

  def self.down
    remove_column :financial_transactions, :invoice_date
  end
end

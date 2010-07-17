class AddInvoiceNumberLineNumberToFinTrans < ActiveRecord::Migration
  def self.up
    add_column :financial_transactions, :invoice_number, :string
    add_column :financial_transactions, :csv_line_number, :integer
  end

  def self.down
    remove_column :financial_transactions, :csv_line_number
    remove_column :financial_transactions, :invoice_number
  end
end

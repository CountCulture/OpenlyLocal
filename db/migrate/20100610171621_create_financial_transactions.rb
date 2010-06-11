class CreateFinancialTransactions < ActiveRecord::Migration
  def self.up
    create_table :financial_transactions do |t|
      t.text :description
      t.string :uid
      t.integer :supplier_id
      t.date :date
      t.value :integer
      t.string :department_name
      t.string :service
      t.string :cost_centre
      t.text :source_url
      t.float :value
      t.string :transaction_type
      t.integer :date_fuzziness
      t.timestamps
    end
  end

  def self.down
    drop_table :financial_transactions
  end
end

class AddAverageSpendFieldsToSpendingStat < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :total_spend, :double
    add_column :spending_stats, :average_monthly_spend, :double
    add_column :spending_stats, :average_transaction_value, :double
    Supplier.all(:conditions => 'total_spend IS NOT NULL').each do |supplier|
      SpendingStat.create!(:organisation => supplier, :total_spend => supplier.total_spend, :average_monthly_spend => supplier.average_monthly_spend)
    end
  end

  def self.down
    remove_column :spending_stats, :total_spend
    remove_column :spending_stats, :average_monthly_spend
    remove_column :spending_stats, :average_transaction_value
  end
end

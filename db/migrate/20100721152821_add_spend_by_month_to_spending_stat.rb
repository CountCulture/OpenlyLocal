class AddSpendByMonthToSpendingStat < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :spend_by_month, :text
  end

  def self.down
    remove_column :spending_stats, :spend_by_month
  end
end

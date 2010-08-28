class AddBreakdownToSpendingStat < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :breakdown, :text
  end

  def self.down
    remove_column :spending_stats, :breakdown
  end
end

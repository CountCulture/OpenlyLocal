class AddTotalSpendIndexToSpendingStat < ActiveRecord::Migration
  def self.up
    add_index :spending_stats, [:organisation_type, :total_spend]
  end

  def self.down
    remove_index :spending_stats, [:organisation_type, :total_spend]
  end
end
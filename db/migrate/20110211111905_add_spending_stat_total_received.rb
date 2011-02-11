class AddSpendingStatTotalReceived < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :total_received, :integer
    rename_column :spending_stats, :total_council_spend, :total_received_from_councils
  end

  def self.down
    rename_column :spending_stats, :total_received_from_councils, :total_council_spend
    remove_column :spending_stats, :total_received
  end
end
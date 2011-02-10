class AddTotalCouncilSpendToSpendingStat < ActiveRecord::Migration
  def self.up
    add_column :spending_stats, :total_council_spend, :integer
    add_column :spending_stats, :payer_breakdown, :text
  end

  def self.down
    remove_column :spending_stats, :payer_breakdwon
    remove_column :spending_stats, :total_council_spend
  end
end
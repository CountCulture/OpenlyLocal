class CreateSpendingStats < ActiveRecord::Migration
  def self.up
    create_table :spending_stats do |t|
      t.string :organisation_type
      t.integer :organisation_id
      t.timestamps
    end
  end

  def self.down
    drop_table :spending_stats
  end
end

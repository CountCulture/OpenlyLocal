class AddNextDueToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :next_due, :datetime
    add_column :scrapers, :frequency, :integer, :limit => 1, :default => 7
    add_index :scrapers, :next_due
  end

  def self.down
    remove_index :scrapers, :next_due
    remove_column :scrapers, :frequency
    remove_column :scrapers, :next_due
  end
end

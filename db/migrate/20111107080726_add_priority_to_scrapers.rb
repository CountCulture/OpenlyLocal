class AddPriorityToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :priority, :integer, :limit => 1, :default => 4
    add_index :scrapers, [:priority, :next_due]
    remove_index :scrapers, :next_due
    Scraper.reset_column_information
    CsvScraper.reset_column_information # just in case
    CsvScraper.update_all(:priority => -1) # so these aren't run
  end

  def self.down
    add_index :scrapers, :next_due
    remove_index :scrapers, [:priority, :next_due]
    remove_column :scrapers, :priority
  end
end

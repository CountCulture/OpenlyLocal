class CreateScrapes < ActiveRecord::Migration
  def self.up
    create_table :scrapes do |t|
      t.integer :scraper_id
      t.string :results_summary
      t.text :results
      t.text :scraping_errors
      t.datetime :created_at
    end
    
    add_index :scrapes, [:scraper_id, :created_at]
  end

  def self.down
    remove_index :scrapes, [:scraper_id, :created_at]
    drop_table :scrapes
  end
end

class AddUseNokogiriFlagToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :parsing_library, :string, :limit => 1, :default => 'H'
  end

  def self.down
    remove_column :scrapers, :use_nokogiri
  end
end

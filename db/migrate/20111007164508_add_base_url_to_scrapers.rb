class AddBaseUrlToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :base_url, :string
  end

  def self.down
    remove_column :scrapers, :base_url
  end
end

class AddSessionInitialisationUrlToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :cookie_url, :string
  end

  def self.down
    remove_column :scrapers, :cookie_url
  end
end

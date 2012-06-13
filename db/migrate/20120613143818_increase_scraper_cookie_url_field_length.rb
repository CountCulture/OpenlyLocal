class IncreaseScraperCookieUrlFieldLength < ActiveRecord::Migration
  def self.up
    change_column :scrapers, :cookie_url, :text
  end

  def self.down
    change_column :scrapers, :cookie_url, :string
  end
end

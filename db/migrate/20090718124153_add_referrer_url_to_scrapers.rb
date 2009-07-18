class AddReferrerUrlToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :referrer_url, :string
  end

  def self.down
    remove_column :scrapers, :referrer_url
  end
end

class LengthenScraperUrl < ActiveRecord::Migration
  def self.up
    change_column :scrapers, :url, :text
  end

  def self.down
    change_column :scrapers, :url, :string
  end
end
class ConvertPlanningAppsDateScrapedToRetrievedAt < ActiveRecord::Migration
  def self.up
    rename_column :planning_applications, :date_scraped, :retrieved_at
    rename_column :planning_applications, :info_url, :url
  end

  def self.down
    rename_column :planning_applications, :url, :info_url
    rename_column :planning_applications, :retrieved_at, :date_scraped
  end
end

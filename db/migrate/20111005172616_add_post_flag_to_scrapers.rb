class AddPostFlagToScrapers < ActiveRecord::Migration
  def self.up
    add_column :scrapers, :use_post, :boolean, :default => false
  end

  def self.down
    remove_column :scrapers, :use_post
  end
end

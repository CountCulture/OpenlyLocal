class AddPublishedAtIndexForFeedEntries < ActiveRecord::Migration
  def self.up
    add_index :feed_entries, :published_at
  end

  def self.down
    remove_index :feed_entries, :published_at
  end
end
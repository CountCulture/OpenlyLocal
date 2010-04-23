class AddGuidIndexToFeedEntries < ActiveRecord::Migration
  def self.up
    add_index :feed_entries, :guid
  end

  def self.down
    remove_index :feed_entries, :guid
  end
end

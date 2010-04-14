class AddLatLngToFeedEntries < ActiveRecord::Migration
  def self.up
    add_column :feed_entries, :lat, :double
    add_column :feed_entries, :lng, :double
  end

  def self.down
    remove_column :feed_entries, :lat
    remove_column :feed_entries, :lng
  end
end

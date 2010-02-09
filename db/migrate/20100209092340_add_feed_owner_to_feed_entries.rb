class AddFeedOwnerToFeedEntries < ActiveRecord::Migration
  def self.up
    add_column :feed_entries, :feed_owner_type, :string
    add_column :feed_entries, :feed_owner_id, :integer
  end

  def self.down
    remove_column :feed_entries, :feed_owner_id
    remove_column :feed_entries, :feed_owner_type
  end
end

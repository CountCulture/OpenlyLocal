class AddFeedUrlToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :feed_url, :string
  end

  def self.down
    remove_column :councils, :feed_url
  end
end

class AddUidUrlToElections < ActiveRecord::Migration
  def self.up
    add_column :elections, :uid, :string
    add_column :elections, :url, :string
  end

  def self.down
    remove_column :elections, :url
    remove_column :elections, :uid
  end
end

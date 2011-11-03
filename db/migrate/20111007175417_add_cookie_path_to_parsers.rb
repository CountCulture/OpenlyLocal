class AddCookiePathToParsers < ActiveRecord::Migration
  def self.up
    add_column :parsers, :cookie_path, :string
  end

  def self.down
    remove_column :parsers, :cookie_path
  end
end

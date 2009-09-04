class AddUrlToWards < ActiveRecord::Migration
  def self.up
    add_column :wards, :url, :string
  end

  def self.down
    remove_column :wards, :url
  end
end

class AddUrlToSuppliers < ActiveRecord::Migration
  def self.up
    add_column :suppliers, :url, :string
  end

  def self.down
    remove_column :suppliers, :url
  end
end

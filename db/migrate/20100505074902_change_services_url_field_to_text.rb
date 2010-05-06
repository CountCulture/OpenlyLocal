class ChangeServicesUrlFieldToText < ActiveRecord::Migration
  def self.up
    change_column :services, :url, :text
  end

  def self.down
    change_column :services, :url, :string
  end
end

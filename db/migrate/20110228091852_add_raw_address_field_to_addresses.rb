class AddRawAddressFieldToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :raw_address, :text
  end

  def self.down
    remove_column :addresses, :raw_address
  end
end
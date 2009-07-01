class AddAddressToMembers < ActiveRecord::Migration
  def self.up
    add_column :members, :address, :text
  end

  def self.down
    remove_column :members, :address
  end
end

class AddLatLngToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :lat, :double
    add_column :addresses, :lng, :double
    add_index :addresses, [:lat, :lng]
  end

  def self.down
    remove_index :addresses, [:lat, :lng]
    remove_column :addresses, :lng
    remove_column :addresses, :lat
  end
end
class AddRegionToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :region, :string
    add_column :addresses, :former, :boolean, :default => false
  end

  def self.down
    remove_column :addresses, :former
    remove_column :addresses, :region
  end
end

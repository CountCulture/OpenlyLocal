class AddIndicesToServices < ActiveRecord::Migration
  def self.up
    add_index :services, :council_id
  end

  def self.down
    remove_index :services, :council_id
  end
end

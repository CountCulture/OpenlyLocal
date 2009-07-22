class AddSnacCodeToWards < ActiveRecord::Migration
  def self.up
    add_column :wards, :snac_id, :string
  end

  def self.down
    remove_column :wards, :snac_id
  end
end

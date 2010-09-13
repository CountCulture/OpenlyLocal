class AddCharityNumberIndexToCharities < ActiveRecord::Migration
  def self.up
    add_index :charities, :charity_number
  end

  def self.down
    remove_index :charities, :charity_number
  end
end

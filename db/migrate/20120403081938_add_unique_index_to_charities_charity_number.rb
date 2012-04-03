class AddUniqueIndexToCharitiesCharityNumber < ActiveRecord::Migration
  def self.up
    remove_index :charities, :charity_number
    add_index :charities, :charity_number, :unique => true
  end

  def self.down
    remove_index :charities, :charity_number
    add_index :charities, :charity_number
  end
end

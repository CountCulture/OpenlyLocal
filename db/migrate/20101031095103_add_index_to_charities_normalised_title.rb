class AddIndexToCharitiesNormalisedTitle < ActiveRecord::Migration
  def self.up
    add_index :charities, :normalised_title, :length => 16
  end

  def self.down
    remove_index :charities, :normalised_title, :length => 16
  end
end

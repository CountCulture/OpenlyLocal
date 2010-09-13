class AddNormalisedTitleToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :normalised_title, :string
  end

  def self.down
    remove_column :charities, :normalised_title
  end
end

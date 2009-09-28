class AddNormalisedTitleToCommittees < ActiveRecord::Migration
  def self.up
    add_column :committees, :normalised_title, :string
  end

  def self.down
    remove_column :committees, :normalised_title
  end
end

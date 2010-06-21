class AddNormalisedTitleToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :normalised_title, :string
  end

  def self.down
    remove_column :councils, :normalised_title
  end
end

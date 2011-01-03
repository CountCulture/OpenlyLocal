class ChangeCharitiesOtherNamesToTextField < ActiveRecord::Migration
  def self.up
    change_column :charities, :other_names, :text
  end

  def self.down
    change_column :charities, :other_names, :string
  end
end
class AddOtherAttributesToEntities < ActiveRecord::Migration
  def self.up
    add_column :entities, :other_attributes, :text
  end

  def self.down
    remove_column :entities, :other_attributes
  end
end

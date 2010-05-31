class DeleteBoundingBoxFromBoundaries < ActiveRecord::Migration
  def self.up
    remove_column :boundaries, :bounding_box
  end

  def self.down
    add_column :boundaries, :bounding_box, :polygon
  end
end

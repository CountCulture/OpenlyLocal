class CreateBoundaries < ActiveRecord::Migration
  def self.up
    create_table :boundaries do |t|
      t.string  :area_type
      t.integer :area_id
      t.column "bounding_box", :polygon
      t.timestamps
    end
  end

  def self.down
    drop_table :boundaries
  end
end

class CreateCachedPostcodes < ActiveRecord::Migration
  def self.up
    create_table :cached_postcodes do |t|
      t.string  :code
      t.integer :output_area_id

      t.timestamps
    end
    rename_table :lsoas, :output_areas
  end

  def self.down
    rename_table :output_areas, :lsoas
    drop_table :cached_postcodes
  end
end

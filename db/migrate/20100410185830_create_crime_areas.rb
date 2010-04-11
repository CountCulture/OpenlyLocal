class CreateCrimeAreas < ActiveRecord::Migration
  def self.up
    create_table :crime_areas do |t|
      t.integer  :uid
      t.integer  :police_force_id
      t.string   :name
      t.integer  :level
      t.integer  :parent_area_id
      t.timestamps
    end
  end

  def self.down
    drop_table :crime_areas
  end
end

class CreateOutputAreaClassifications < ActiveRecord::Migration
  def self.up
    create_table :output_area_classifications do |t|
      t.string :title
      t.string :uid
      t.string :area_type
      t.integer :level
    end
  end

  def self.down
    drop_table :output_area_classifications
  end
end

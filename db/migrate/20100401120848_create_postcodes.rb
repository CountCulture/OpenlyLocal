class CreatePostcodes < ActiveRecord::Migration
  def self.up
    create_table :postcodes do |t|
      t.string  :code
      t.integer :quality
      t.string  :country
      t.string  :nhs_region
      t.string  :nhs_health_authority
      t.integer :county_id
      t.integer :district_id
      t.integer :ward_id
    end
    add_column :postcodes, :lat, :double
    add_column :postcodes, :lng, :double
  end

  def self.down
    drop_table :postcodes
  end
end

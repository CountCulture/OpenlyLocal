class RemoveCachedPostcodes < ActiveRecord::Migration
  def self.up
    drop_table :cached_postcodes
  end

  def self.down
    create_table "cached_postcodes", :force => true do |t|
      t.column "code", :string
      t.column "output_area_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    
  end
end

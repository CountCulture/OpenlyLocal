class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.text :street_address 
      t.string :locality
      t.string :postal_code
      t.string :country
      t.string :addressee_type
      t.integer :addressee_id
      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end

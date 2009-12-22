class CreatePoliceAuthorities < ActiveRecord::Migration
  def self.up
    create_table :police_authorities do |t|
      t.string  :name
      t.string  :url
      t.text    :address
      t.string  :telephone
      t.string  :wdtk_name
      t.string  :wikipedia_url
      t.integer :police_force_id
      t.timestamps
    end
  end

  def self.down
    drop_table :police_authorities
  end
end

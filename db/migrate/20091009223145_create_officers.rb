class CreateOfficers < ActiveRecord::Migration
  def self.up
    create_table :officers do |t|
      t.string  :first_name
      t.string  :last_name
      t.string  :name_title
      t.string  :qualifications
      t.string  :position
      t.integer :council_id
      t.string  :url
      t.timestamps
    end
  end

  def self.down
    drop_table :officers
  end
end

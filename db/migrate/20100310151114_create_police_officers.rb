class CreatePoliceOfficers < ActiveRecord::Migration
  def self.up
    create_table :police_officers do |t|
      t.string :name
      t.string :rank
      t.text :biography
      t.integer :police_team_id
      t.timestamps
    end
  end

  def self.down
    drop_table :police_officers
  end
end

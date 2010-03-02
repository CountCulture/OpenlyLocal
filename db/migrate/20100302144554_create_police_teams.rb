class CreatePoliceTeams < ActiveRecord::Migration
  def self.up
    create_table :police_teams do |t|
      t.string  :name
      t.string  :uid
      t.text    :description
      t.string  :url
      t.integer :police_force_id
      t.timestamps
    end
  end

  def self.down
    drop_table :police_teams
  end
end

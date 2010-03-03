class AddFieldsToPoliceTeamsEtc < ActiveRecord::Migration
  def self.up
    add_column :police_forces, :crime_map, :string
    add_column :police_teams, :lat, :double
    add_column :police_teams, :lng, :double
  end

  def self.down
    remove_column :police_teams, :lng
    remove_column :police_teams, :lat
    remove_column :police_forces, :crime_map
  end
end

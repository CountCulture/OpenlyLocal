class AddDefunktFlagToPoliceTeam < ActiveRecord::Migration
  def self.up
    add_column :police_teams, :defunkt, :boolean, :default => false
  end

  def self.down
    remove_column :police_teams, :defunkt
  end
end

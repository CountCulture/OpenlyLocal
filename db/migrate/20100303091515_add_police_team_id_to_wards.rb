class AddPoliceTeamIdToWards < ActiveRecord::Migration
  def self.up
    add_column :wards, :police_team_id, :integer
  end

  def self.down
    remove_column :wards, :police_team_id
  end
end

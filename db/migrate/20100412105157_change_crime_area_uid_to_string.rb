class ChangeCrimeAreaUidToString < ActiveRecord::Migration
  def self.up
    change_column :crime_areas, :uid, :string
  end

  def self.down
    change_column :crime_areas, :uid, :integer
  end
end

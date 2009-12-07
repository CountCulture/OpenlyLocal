class AddWdtkIdToPoliceForces < ActiveRecord::Migration
  def self.up
    add_column :police_forces, :wdtk_name, :string
  end

  def self.down
    remove_column :police_forces, :wdtk_name
  end
end

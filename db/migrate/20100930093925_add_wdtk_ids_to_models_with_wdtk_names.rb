class AddWdtkIdsToModelsWithWdtkNames < ActiveRecord::Migration
  def self.up
    add_column :police_forces, :wdtk_id, :integer
    add_column :police_authorities, :wdtk_id, :integer
    add_column :pension_funds, :wdtk_id, :integer
  end

  def self.down
    remove_column :pension_funds, :wdtk_id
    remove_column :police_authorities, :wdtk_id
    remove_column :police_forces, :wdtk_id
  end
end

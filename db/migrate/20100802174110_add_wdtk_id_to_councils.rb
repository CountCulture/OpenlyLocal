class AddWdtkIdToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :wdtk_id, :integer
  end

  def self.down
    remove_column :councils, :wdtk_id
  end
end

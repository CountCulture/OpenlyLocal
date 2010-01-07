class AddRegionToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :region, :string
  end

  def self.down
    remove_column :councils, :region
  end
end

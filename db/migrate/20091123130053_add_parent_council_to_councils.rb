class AddParentCouncilToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :parent_authority_id, :integer
  end

  def self.down
    remove_column :councils, :parent_authority_id
  end
end

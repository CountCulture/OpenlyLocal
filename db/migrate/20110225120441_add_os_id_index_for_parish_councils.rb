class AddOsIdIndexForParishCouncils < ActiveRecord::Migration
  def self.up
    change_column :parish_councils, :council_id, :integer
    add_index :parish_councils, :os_id, :length => 16
    add_index :parish_councils, :council_id
    add_index :parish_councils, :title, :length => 16
  end

  def self.down
    change_column :parish_councils, :council_id, :string
    remove_index :parish_councils, :title
    remove_index :parish_councils, :council_id
    remove_index :parish_councils, :os_id
  end
end
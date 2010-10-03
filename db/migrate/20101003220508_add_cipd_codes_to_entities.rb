class AddCipdCodesToEntities < ActiveRecord::Migration
  def self.up
    add_column :entities, :cpid_code, :string
    add_column :entities, :normalised_title, :string
  end

  def self.down
    remove_column :entities, :normalised_title
    remove_column :entities, :cpid_code
  end
end

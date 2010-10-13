class AddResourceUriToEntities < ActiveRecord::Migration
  def self.up
    add_column :entities, :resource_uri, :string
  end

  def self.down
    remove_column :entities, :resource_uri
  end
end

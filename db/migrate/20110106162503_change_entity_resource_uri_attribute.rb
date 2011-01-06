class ChangeEntityResourceUriAttribute < ActiveRecord::Migration
  def self.up
    rename_column :entities, :resource_uri, :external_resource_uri
  end

  def self.down
    rename_column :entities, :external_resource_uri, :resource_uri
  end
end
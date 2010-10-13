class UpdateWdtkRequests < ActiveRecord::Migration
  def self.up
    WdtkRequest.destroy_all
    add_column :wdtk_requests, :organisation_type, :string
    rename_column :wdtk_requests, :council_id, :organisation_id
    add_column :wdtk_requests, :uid, :integer
    add_column :wdtk_requests, :related_object_type, :string
    add_column :wdtk_requests, :related_object_id, :integer
    add_column :wdtk_requests, :request_name, :string
    remove_column :wdtk_requests, :url
  end

  def self.down
    add_column :wdtk_requests, :url, :string
    remove_column :wdtk_requests, :request_name
    remove_column :wdtk_requests, :related_object_id
    remove_column :wdtk_requests, :related_object_type
    remove_column :wdtk_requests, :uid
    rename_column :wdtk_requests, :organisation_id, :council_id
    remove_column :wdtk_requests, :organisation_type
  end
end

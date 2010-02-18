class AddNpiaNameToPoliceForces < ActiveRecord::Migration
  def self.up
    add_column :police_forces, :npia_id, :string
    add_column :police_forces, :youtube_account_name, :string
    add_column :police_forces, :facebook_account_name, :string
    add_column :police_forces, :feed_url, :string
    remove_column :police_forces, :police_authority_url
  end

  def self.down
    add_column :police_forces, :police_authority_url, :string
    remove_column :police_forces, :feed_url
    remove_column :police_forces, :facebook_account_name
    remove_column :police_forces, :youtube_account_name
    remove_column :police_forces, :npia_id
  end
end

class AddPlatformToHyperlocalSite < ActiveRecord::Migration
  def self.up
    add_column :hyperlocal_sites, :platform, :string
  end

  def self.down
    remove_column :hyperlocal_sites, :platform
  end
end

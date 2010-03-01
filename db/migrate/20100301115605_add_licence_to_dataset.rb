class AddLicenceToDataset < ActiveRecord::Migration
  def self.up
    add_column :datasets, :licence, :string
  end

  def self.down
    remove_column :datasets, :licence
  end
end

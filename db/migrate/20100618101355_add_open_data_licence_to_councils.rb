class AddOpenDataLicenceToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :open_data_licence, :string
  end

  def self.down
    remove_column :councils, :open_data_licence
  end
end

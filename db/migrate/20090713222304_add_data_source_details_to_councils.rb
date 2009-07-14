class AddDataSourceDetailsToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :data_source_url, :string
    add_column :councils, :data_source_name, :string
  end

  def self.down
    remove_column :councils, :source_name
    remove_column :councils, :source_url
  end
end

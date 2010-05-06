class AddOpenDataUrlToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :open_data_url, :string
  end

  def self.down
    remove_column :councils, :open_data_url
  end
end

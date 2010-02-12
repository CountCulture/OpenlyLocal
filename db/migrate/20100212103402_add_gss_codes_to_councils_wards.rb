class AddGssCodesToCouncilsWards < ActiveRecord::Migration
  def self.up
    add_column :councils, :gss_code, :string, :length => 10
    add_column :wards, :gss_code, :string, :length => 10
  end

  def self.down
    remove_column :wards, :gss_code
    remove_column :councils, :gss_code
  end
end

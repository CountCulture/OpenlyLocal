class FixParishCouncilTextColumns < ActiveRecord::Migration
  def self.up
    change_column :parish_councils, :title, :string
    change_column :parish_councils, :os_id, :string
    change_column :parish_councils, :gss_code, :string
    change_column :parish_councils, :normalised_title, :string
    change_column :parish_councils, :vat_number, :string
    change_column :parish_councils, :wdtk_name, :string    
  end

  def self.down
    change_column :parish_councils, :title, :text
    change_column :parish_councils, :os_id, :text
    change_column :parish_councils, :gss_code, :text
    change_column :parish_councils, :normalised_title, :text
    change_column :parish_councils, :vat_number, :text
    change_column :parish_councils, :wdtk_name, :text
  end
end

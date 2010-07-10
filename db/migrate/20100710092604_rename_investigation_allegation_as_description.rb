class RenameInvestigationAllegationAsDescription < ActiveRecord::Migration
  def self.up
    rename_column :investigations, :allegation, :description
    add_column :investigations, :full_report_url, :string
  end

  def self.down
    # remove_column :investigations, :full_report_url
    rename_column :investigations, :description, :allegation
  end
end

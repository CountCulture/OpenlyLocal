class CreateInvestigationSubjectConnections < ActiveRecord::Migration
  def self.up
    create_table :investigation_subject_connections do |t|
      t.integer :investigation_id
      t.integer :subject_id
      t.string  :subject_type
    end
    add_column :investigations, :related_organisation_type, :string
    add_column :investigations, :related_organisation_id, :integer
    rename_column :investigations, :organisation_name, :related_organisation_name
  end

  def self.down
    rename_column :investigations, :related_organisation_name, :organisation_name
    drop_table :investigation_subject_connections
    remove_column :investigations, :related_organisation_id
    remove_column :investigations, :related_organisation_type
  end
end

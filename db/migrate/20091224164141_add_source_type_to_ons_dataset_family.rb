class AddSourceTypeToOnsDatasetFamily < ActiveRecord::Migration
  def self.up
    add_column :ons_dataset_families, :source_type, :string
    OnsDatasetFamily.update_all("source_type = 'Ness'")
    add_column :councils, :cipfa_code, :string
    remove_column :ons_dataset_families, :ons_subject_id
  end

  def self.down
    add_column :ons_dataset_families, :ons_subject_id, :integer
    remove_column :councils, :cipfa_code
    remove_column :ons_dataset_families, :source_type
  end
end

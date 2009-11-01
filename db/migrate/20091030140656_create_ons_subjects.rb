class CreateOnsSubjects < ActiveRecord::Migration
  def self.up
    create_table :ons_subjects do |t|
      t.string :title
      t.integer :ons_uid
      t.timestamps
    end
    add_column :ons_datasets, :ons_subject_id, :integer
    rename_column :ons_datasets, :ds_family_id, :ons_uid
  end

  def self.down
    # rename_column :ons_datasets, :ons_uid, :ds_family_id
    remove_column :ons_datasets, :ons_subject_id
    drop_table :ons_subjects
  end
end

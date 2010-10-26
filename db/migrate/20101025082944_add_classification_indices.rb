class AddClassificationIndices < ActiveRecord::Migration
  def self.up
    add_index :classification_links, [:classified_id, :classified_type]
    add_index :classification_links, :classification_id
    add_index :charity_annual_reports, :charity_id
  end

  def self.down
    remove_index :classification_links, :classification_id
    remove_index :classification_links, [:classified_id, :classified_type]
    remove_index :charity_annual_reports, :charity_id
  end
end

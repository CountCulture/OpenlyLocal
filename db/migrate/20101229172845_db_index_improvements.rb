class DbIndexImprovements < ActiveRecord::Migration
  def self.up
    remove_index :documents, [:document_owner_type, :document_owner_id]
    add_index :documents, [:document_owner_id, :document_owner_type]
  end

  def self.down
    remove_index :documents, [:document_owner_id, :document_owner_type]
    add_index :documents, [:document_owner_type, :document_owner_id]
  end
end
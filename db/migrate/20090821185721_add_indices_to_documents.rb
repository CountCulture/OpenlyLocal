class AddIndicesToDocuments < ActiveRecord::Migration
  def self.up
    add_index :documents, [ :document_owner_type, :document_owner_id ]
  end

  def self.down
    remove_index :documents, [ :document_owner_type, :document_owner_id ]
  end
end

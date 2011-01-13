class AddDocumentUrlIndex < ActiveRecord::Migration
  def self.up
    add_index :documents, :url, :length => 64
  end

  def self.down
    remove_index :documents, :url 
  end
end
class ExtendLengthOfDocumentBody < ActiveRecord::Migration
  def self.up
    change_column :documents, :body, :text, :limit => 16777215
    change_column :documents, :raw_body, :text, :limit => 16777215
  end

  def self.down
    change_column :documents, :body, :text
    change_column :documents, :raw_body, :text
  end
end

class AddPrecisToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :precis, :text
  end

  def self.down
    remove_column :documents, :precis
  end
end

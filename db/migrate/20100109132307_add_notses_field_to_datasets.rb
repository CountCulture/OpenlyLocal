class AddNotsesFieldToDatasets < ActiveRecord::Migration
  def self.up
    add_column :datasets, :notes, :text
  end

  def self.down
    remove_column :datasets, :notes
  end
end

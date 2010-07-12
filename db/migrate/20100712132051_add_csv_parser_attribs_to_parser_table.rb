class AddCsvParserAttribsToParserTable < ActiveRecord::Migration
  def self.up
    add_column :parsers, :type, :string
    add_column :parsers, :attribute_mapping, :text
  end

  def self.down
    remove_column :parsers, :attribute_mapping
    remove_column :parsers, :type
  end
end

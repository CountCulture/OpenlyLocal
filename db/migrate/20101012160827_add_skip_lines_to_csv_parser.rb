class AddSkipLinesToCsvParser < ActiveRecord::Migration
  def self.up
    add_column :parsers, :skip_rows, :integer
  end

  def self.down
    remove_column :parsers, :skip_rows
  end
end

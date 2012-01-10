class AddCouncilTypeToParishCouncils < ActiveRecord::Migration
  def self.up
    add_column :parish_councils, :council_type, :string, :limit => 8
  end

  def self.down
    remove_column :parish_councils, :council_type
  end
end

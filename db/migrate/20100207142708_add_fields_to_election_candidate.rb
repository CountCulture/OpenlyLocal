class AddFieldsToElectionCandidate < ActiveRecord::Migration
  def self.up
    add_column :candidates, :address, :text
    add_column :elections, :electorate, :integer
  end

  def self.down
    remove_column :elections, :electorate
    remove_column :candidates, :address
  end
end

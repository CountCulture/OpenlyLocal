class RenameCandidateAddress < ActiveRecord::Migration
  def self.up
    rename_column :candidates, :address, :basic_address
  end

  def self.down
    rename_column :candidates, :basic_address, :address
  end
end

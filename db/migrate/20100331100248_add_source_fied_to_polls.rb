class AddSourceFiedToPolls < ActiveRecord::Migration
  def self.up
    add_column :polls, :source, :string
    add_column :polls, :uncontested, :boolean, :default => false
  end

  def self.down
    remove_column :polls, :uncontested
    remove_column :polls, :source
  end
end

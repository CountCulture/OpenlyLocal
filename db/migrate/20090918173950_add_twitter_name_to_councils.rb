class AddTwitterNameToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :twitter_account, :string
  end

  def self.down
    remove_column :councils, :twitter_account
  end
end

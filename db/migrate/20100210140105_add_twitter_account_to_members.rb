class AddTwitterAccountToMembers < ActiveRecord::Migration
  def self.up
    add_column :members, :twitter_account, :string
    add_column :members, :blog_url, :string
  end

  def self.down
    remove_column :members, :blog_url
    remove_column :members, :twitter_account
  end
end

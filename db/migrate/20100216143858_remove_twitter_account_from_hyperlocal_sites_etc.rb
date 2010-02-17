class RemoveTwitterAccountFromHyperlocalSitesEtc < ActiveRecord::Migration
  def self.up
    remove_column :hyperlocal_sites, :twitter_account
    remove_column :councils, :twitter_account
    remove_column :members, :twitter_account
  end

  def self.down
    add_column :members, :twitter_account, :string
    add_column :councils, :twitter_account, :string
    add_column :hyperlocal_sites, :twitter_account, :string
  end
end

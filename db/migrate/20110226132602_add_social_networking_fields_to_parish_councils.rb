class AddSocialNetworkingFieldsToParishCouncils < ActiveRecord::Migration
  def self.up
    add_column :parish_councils, :feed_url, :string
    add_column :parish_councils, :facebook_account_name, :string
    add_column :parish_councils, :youtube_account_name, :string
  end

  def self.down
    remove_column :parish_councils, :youtube_account_name
    remove_column :parish_councils, :facebook_account_name
    remove_column :parish_councils, :feed_url
  end
end
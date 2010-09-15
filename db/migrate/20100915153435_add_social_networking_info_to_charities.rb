class AddSocialNetworkingInfoToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :facebook_account_name, :string
    add_column :charities, :youtube_account_name, :string
    add_column :charities, :feed_url, :string
    add_column :charities, :governing_document, :text
    change_column :charities, :activities, :text
  end

  def self.down
    change_column :charities, :activities, :string
    remove_column :charities, :governing_document
    remove_column :charities, :feed_url
    remove_column :charities, :youtube_account_name
    remove_column :charities, :facebook_account_name
  end
end

class CreateHyperlocalSites < ActiveRecord::Migration
  def self.up
    create_table :hyperlocal_sites do |t|
      t.string    :title
      t.string    :url
      t.string    :email
      t.string    :twitter_account
      t.string    :feed_url
      t.float     :lat
      t.float     :lng
      t.float     :distance    
      t.timestamps
    end
  end

  def self.down
    drop_table :hyperlocal_sites
  end
end

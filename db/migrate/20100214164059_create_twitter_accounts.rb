class CreateTwitterAccounts < ActiveRecord::Migration
  def self.up
    create_table :twitter_accounts do |t|
      t.string  :name
      t.integer :user_id
      t.string  :user_type
      t.integer :twitter_id
      t.integer :follower_count
      t.integer :following_count
      t.text    :last_tweet
      t.timestamps
    end
  end

  def self.down
    drop_table :twitter_accounts
  end
end

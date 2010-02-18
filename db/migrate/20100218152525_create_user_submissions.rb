class CreateUserSubmissions < ActiveRecord::Migration
  def self.up
    create_table :user_submissions do |t|
      t.string :twitter_account_name 
      t.integer :council_id 
      t.integer :member_id
      t.string :member_name
      t.string :blog_url
      t.string :facebook_account_name
      t.string :linked_in_account_name
      t.timestamps
    end
    add_column :members, :facebook_account_name, :string
    add_column :members, :linked_in_account_name, :string
  end

  def self.down
    remove_column :members, :linked_in_account_name
    remove_column :members, :facebook_account_name
    drop_table :twitter_submissions
  end
end

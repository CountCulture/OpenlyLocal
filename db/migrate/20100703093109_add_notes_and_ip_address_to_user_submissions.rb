class AddNotesAndIpAddressToUserSubmissions < ActiveRecord::Migration
  def self.up
    add_column :user_submissions, :ip_address, :string
    add_column :user_submissions, :notes, :text
  end

  def self.down
    remove_column :user_submissions, :notes
    remove_column :user_submissions, :ip_address
  end
end

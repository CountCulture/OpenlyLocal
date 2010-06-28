class AddSubmissionDetailsToUserSubmission < ActiveRecord::Migration
  def self.up
    add_column :user_submissions, :submission_details, :text
    add_column :user_submissions, :item_type, :string
    rename_column :user_submissions, :council_id, :item_id
    UserSubmission.update_all("item_type = 'Council'")
  end

  def self.down
    rename_column :user_submissions, :item_id, :council_id
    remove_column :user_submissions, :item_type
    remove_column :user_submissions, :submission_details
  end
end

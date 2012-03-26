class AddPostcodeIdToAlertSubscribers < ActiveRecord::Migration
  def self.up
    add_column :alert_subscribers, :postcode_id, :integer
    rename_column :alert_subscribers, :postcode, :postcode_text
  end

  def self.down
    rename_column :alert_subscribers, :postcode_text, :postcode
    remove_column :alert_subscribers, :postcode_id
  end
end

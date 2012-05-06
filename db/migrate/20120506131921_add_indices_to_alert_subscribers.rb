class AddIndicesToAlertSubscribers < ActiveRecord::Migration
  def self.up
    add_index :alert_subscribers, [:top_right_lat, :top_right_lng, :bottom_left_lat, :bottom_left_lng]
    add_index :alert_subscribers, :email
    add_index :alert_subscribers, :created_at
  end

  def self.down
    remove_index :alert_subscribers, :created_at
    remove_index :alert_subscribers, :email
    remove_index :alert_subscribers, [:top_right_lat, :top_right_lng, :bottom_left_lat, :bottom_left_lng]
  end
end

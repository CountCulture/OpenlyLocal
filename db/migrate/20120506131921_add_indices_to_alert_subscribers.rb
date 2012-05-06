class AddIndicesToAlertSubscribers < ActiveRecord::Migration
  def self.up
    add_index :alert_subscribers, :email
    add_index :alert_subscribers, :created_at
    add_index :alert_subscribers, [:bottom_left_lat, :top_right_lat, :bottom_left_lng, :top_right_lng], :name => "bounding_box_index"
  end

  def self.down
    remove_index :alert_subscribers, :name => :bounding_box_index
    remove_index :alert_subscribers, :created_at
    remove_index :alert_subscribers, :email
  end
end

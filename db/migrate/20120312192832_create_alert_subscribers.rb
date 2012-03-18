class CreateAlertSubscribers < ActiveRecord::Migration
  def self.up
    create_table :alert_subscribers do |t|
      t.string :email, :limit => 128
      t.string :postcode, :limit => 8
      t.datetime :last_sent
      t.boolean :confirmed
      t.string :confirmation_code
      t.double :lat, :double
      t.double :lng, :double
      t.float :distance
      t.float :bottom_left_lat
      t.float :bottom_left_lng
      t.float :top_right_lat
      t.float :top_right_lng
      t.timestamps
    end
    add_index :alert_subscribers, [:bottom_left_lat, :top_right_lat, :bottom_left_lng, :top_right_lng]
  end

  def self.down
    # remove_index :alert_subscribers, :column => [:bottom_left_lat, :top_right_lat, :bottom_left_lng, :top_right_lng]
    drop_table :alert_subscribers
  end
end

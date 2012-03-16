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
      t.timestamps
    end
  end

  def self.down
    drop_table :alert_subscribers
  end
end

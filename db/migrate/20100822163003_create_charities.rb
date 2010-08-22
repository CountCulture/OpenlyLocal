class CreateCharities < ActiveRecord::Migration
  def self.up
    create_table :charities do |t|
      t.string :title
      t.text :activities
      t.string :charity_number
      t.string :website
      t.string :email
      t.string :telephone
      t.string :charity_commission_url
      t.date :date_registered
      t.timestamps
    end
  end

  def self.down
    drop_table :charities
  end
end

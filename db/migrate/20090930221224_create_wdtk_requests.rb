class CreateWdtkRequests < ActiveRecord::Migration
  def self.up
    create_table :wdtk_requests do |t|
      t.string :title
      t.string :url
      t.string :status
      t.text   :description
      t.integer :council_id
      t.timestamps
    end
  end

  def self.down
    drop_table :wdtk_requests
  end
end

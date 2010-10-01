class CreateClassifications < ActiveRecord::Migration
  def self.up
    create_table :classifications do |t|
      t.string :grouping
      t.string :title
      t.text :extended_title
      t.string :uid
      t.integer :parent_id
      t.timestamps
    end
  end

  def self.down
    drop_table :classifications
  end
end

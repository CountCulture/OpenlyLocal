class CreateClassificationLinks < ActiveRecord::Migration
  def self.up
    create_table :classification_links do |t|
      t.integer :classification_id
      t.string :classified_type
      t.integer :classified_id
    end
  end

  def self.down
    drop_table :classification_links
  end
end

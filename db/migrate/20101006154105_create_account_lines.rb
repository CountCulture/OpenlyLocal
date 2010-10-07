class CreateAccountLines < ActiveRecord::Migration
  def self.up
    create_table :account_lines do |t|
      t.integer :value
      t.string :period
      t.string :sub_heading
      t.integer :classification_id
      t.string :organisation_type
      t.integer :organisation_id
      t.timestamps
    end
  end

  def self.down
    drop_table :account_lines
  end
end

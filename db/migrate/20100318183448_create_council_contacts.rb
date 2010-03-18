class CreateCouncilContacts < ActiveRecord::Migration
  def self.up
    create_table :council_contacts do |t|
      t.string  :name
      t.string  :position
      t.string  :email
      t.integer :council_id
      t.timestamps
    end
  end

  def self.down
    drop_table :council_contacts
  end
end

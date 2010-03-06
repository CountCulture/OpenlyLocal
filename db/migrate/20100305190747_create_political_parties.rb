class CreatePoliticalParties < ActiveRecord::Migration
  def self.up
    create_table :political_parties do |t|
      t.string :name
      t.string :electoral_commission_uid
      t.string :url
      t.string :wikipedia_name
      t.string :colour
      t.text   :alternative_names
      t.timestamps
    end
  end

  def self.down
    drop_table :political_parties
  end
end

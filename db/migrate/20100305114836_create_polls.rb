class CreatePolls < ActiveRecord::Migration
  def self.up
    create_table :polls do |t|
      t.integer :area_id
      t.string :area_type
      t.date :date_held
      t.string :position
      t.integer :electorate
      t.integer :ballots_issued
      t.integer :ballots_rejected
      t.integer :postal_votes
      t.timestamps
    end
  end

  def self.down
    drop_table :polls
  end
end

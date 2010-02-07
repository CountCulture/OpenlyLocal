class CreateCandidates < ActiveRecord::Migration
  def self.up
    create_table :candidates do |t|
      t.integer :ward_id
      t.integer :election_id
      t.string :first_name
      t.string :last_name
      t.string :party
      t.boolean :elected
      t.boolean :votes
      t.timestamps
    end
  end

  def self.down
    drop_table :candidates
  end
end

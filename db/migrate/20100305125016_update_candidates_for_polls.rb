class UpdateCandidatesForPolls < ActiveRecord::Migration
  def self.up
    drop_table :elections
    rename_column :candidates, :election_id, :poll_id
    remove_column :candidates, :ward_id
    change_column :candidates, :votes, :integer
  end

  def self.down
    change_column :candidates, :votes, :string
    rename_column :candidates, :poll_id, :election_id
    add_column :candidates, :ward_id, :integer
    create_table "elections", :force => true do |t|
      t.column "date", :date
      t.column "ward_id", :integer
      t.column "electorate", :integer
      t.column "uid", :string
      t.column "url", :string
    end
    
  end
end

class CreateElections < ActiveRecord::Migration
  def self.up
    create_table :elections do |t|
      t.date :date
      t.integer :ward_id
    end
  end

  def self.down
    drop_table :elections
  end
end

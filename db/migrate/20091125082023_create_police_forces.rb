class CreatePoliceForces < ActiveRecord::Migration
  def self.up
    create_table :police_forces do |t|
      t.string :name
      t.string :url
      t.string :police_authority_url
      t.timestamps
    end
    add_column :councils, :police_force_id, :integer
  end

  def self.down
    remove_column :councils, :police_force_id
    drop_table :police_forces
  end
end

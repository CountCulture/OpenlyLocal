class CreateWards < ActiveRecord::Migration
  def self.up
    create_table :wards do |t|
      t.string      :name
      t.integer     :council_id
      t.timestamps
    end
    add_column :members, :ward_id, :integer
  end

  def self.down
    remove_column :members, :ward_id
    drop_table :wards
  end
end

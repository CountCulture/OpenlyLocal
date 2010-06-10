class CreateSuppliers < ActiveRecord::Migration
  def self.up
    create_table :suppliers do |t|
      t.string :name
      t.string :uid
      t.string :organisation_type
      t.integer :organisation_id
      t.string :company_number
      t.timestamps
    end
  end

  def self.down
    drop_table :suppliers
  end
end

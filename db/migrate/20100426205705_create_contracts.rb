class CreateContracts < ActiveRecord::Migration
  def self.up
    create_table :contracts do |t|
      t.string :title
      t.text :description
      t.string :uid
      t.string :source_url
      t.string :url
      t.integer :organisation_id
      t.string :organisation_type
      t.date :start_date
      t.date :end_date
      t.string :duration
      t.integer :total_value
      t.integer :annual_value
      t.string :supplier_name
      t.text :supplier_address
      t.string :supplier_uid
      t.string :department_responsible
      t.string :person_responsible
      t.string :email
      t.string :telephone
      t.timestamps
    end
  end

  def self.down
    drop_table :contracts
  end
end

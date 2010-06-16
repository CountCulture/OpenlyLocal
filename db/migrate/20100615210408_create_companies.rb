class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :title
      t.string :url
      t.string :company_number
      t.integer :supplier_id
      t.string :normalised_title
      t.timestamps
    end
    add_column :suppliers, :company_id, :integer
  end

  def self.down
    remove_column :suppliers, :company_id
    drop_table :companies
  end
end

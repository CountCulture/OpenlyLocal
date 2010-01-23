class CreatePensionFunds < ActiveRecord::Migration
  def self.up
    create_table :pension_funds do |t|
      t.string  :name
      t.string  :url
      t.string  :telephone
      t.string  :email
      t.string  :fax
      t.text    :address
      t.string  :wdtk_name
      
      t.timestamps
    end
    add_column :councils, :pension_fund_id, :integer
  end

  def self.down
    remove_column :councils, :pension_fund_id
    drop_table :pension_funds
  end
end

class RenameExistingServicesTableAndAddNewServicesTable < ActiveRecord::Migration
  def self.up
    rename_table :services, :ldg_services
    create_table :services, :force => true do |t|
      t.string  :title
      t.string  :url
      t.string  :category
      t.integer :council_id
      t.integer :ldg_service_id
      t.timestamps
    end
  end

  def self.down
    drop_table :services
    rename_table :ldg_services, :services
  end
end

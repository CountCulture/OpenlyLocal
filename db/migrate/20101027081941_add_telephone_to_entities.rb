class AddTelephoneToEntities < ActiveRecord::Migration
  def self.up
    add_column :entities, :telephone, :string
  end

  def self.down
    remove_column :entities, :telephone
  end
end

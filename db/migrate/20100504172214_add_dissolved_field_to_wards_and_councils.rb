class AddDissolvedFieldToWardsAndCouncils < ActiveRecord::Migration
  def self.up
    add_column :wards, :defunkt, :boolean, :default => false
    add_column :councils, :defunkt, :boolean, :default => false
  end

  def self.down
    remove_column :councils, :defunkt
    remove_column :wards, :defunkt
  end
end

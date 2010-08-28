class AddDateRemovedToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :date_removed, :date
  end

  def self.down
    remove_column :charities, :date_removed
  end
end

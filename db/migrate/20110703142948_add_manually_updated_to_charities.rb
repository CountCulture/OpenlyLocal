class AddManuallyUpdatedToCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :manually_updated, :datetime
  end

  def self.down
    remove_column :charities, :manually_updated
  end
end
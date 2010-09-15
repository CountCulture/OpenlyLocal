class AddLastCheckedToCharity < ActiveRecord::Migration
  def self.up
    add_column :charities, :last_checked, :datetime
  end

  def self.down
    remove_column :charities, :last_checked
  end
end

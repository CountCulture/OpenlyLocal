class Add1010FlagForCharities < ActiveRecord::Migration
  def self.up
    add_column :charities, :signed_up_for_1010, :boolean, :default => false
  end

  def self.down
    remove_column :charities, :signed_up_for_1010
  end
end

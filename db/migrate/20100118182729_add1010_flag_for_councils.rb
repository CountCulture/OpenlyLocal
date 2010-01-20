class Add1010FlagForCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :signed_up_for_1010, :boolean, :default => false
  end

  def self.down
    remove_column :councils, :signed_up_for_1010
  end
end

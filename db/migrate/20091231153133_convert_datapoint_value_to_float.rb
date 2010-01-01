class ConvertDatapointValueToFloat < ActiveRecord::Migration
  def self.up
    change_column :ons_datapoints, :value, :float, :limit => 32
  end

  def self.down
    change_column :ons_datapoints, :value, :string
  end
end

class MakeOnsDatapointsPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :ons_datapoints, :area_type, :string
    rename_column :ons_datapoints, :ward_id, :area_id
    OnsDatapoint.update_all("area_type = 'Ward'")
  end

  def self.down
    rename_column :ons_datapoints, :area_id
    remove_column :ons_datapoints, :area_type
  end
end

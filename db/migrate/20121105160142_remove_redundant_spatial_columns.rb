class RemoveRedundantSpatialColumns < ActiveRecord::Migration
  def self.up
    remove_column :alert_subscribers, :geom
    remove_column :postcodes, :geom
    remove_column :planning_applications, :geom
    remove_column :hyperlocal_sites, :geom
  end

  def self.down
    add_column :planning_applications, :geom, :point, :limit => nil, :srid => 4326
    add_column :postcodes, :geom, :point, :limit => nil, :srid => 4326
    add_column :hyperlocal_sites, :geom, :point, :limit => nil, :srid => 4326
    add_column :alert_subscribers, :geom, :point, :limit => nil, :srid => 4326
  end
end

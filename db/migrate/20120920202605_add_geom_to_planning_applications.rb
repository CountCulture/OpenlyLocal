class AddGeomToPlanningApplications < ActiveRecord::Migration
  def self.up
    remove_column :alert_subscribers, :bottom_left_lat
    remove_column :alert_subscribers, :bottom_left_lng
    remove_column :alert_subscribers, :top_right_lat
    remove_column :alert_subscribers, :top_right_lng

    add_column :alert_subscribers, :geom, :point, :srid => 4326
    add_column :planning_applications, :geom, :point, :srid => 4326

    add_index :alert_subscribers, :geom, :spatial => true
    add_index :planning_applications, :geom, :spatial => true

    PlanningApplication.all.each do |record|
      record.update_attribute :geom, Point.from_x_y(record.lng, record.lat, 4326)
    end
  end

  def self.down
    add_column :alert_subscribers, :bottom_left_lat, :float
    add_column :alert_subscribers, :bottom_left_lng, :float
    add_column :alert_subscribers, :top_right_lat, :float
    add_column :alert_subscribers, :top_right_lng, :float

    remove_column :alert_subscribers, :geom
    remove_column :planning_applications, :geom
  end
end

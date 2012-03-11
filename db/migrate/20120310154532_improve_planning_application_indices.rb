class ImprovePlanningApplicationIndices < ActiveRecord::Migration
  def self.up
    PlanningApplication.connection.execute("ALTER TABLE planning_applications ENGINE=InnoDB")
    add_index :planning_applications, [:council_id, :uid], :unique => true
    remove_index :planning_applications, :council_id
    remove_index :planning_applications, :name => :index_planning_applications_on_lat_and_long_and_retrieved_at
    remove_index :planning_applications, :name => :datescr
    remove_index :planning_applications, :name => :dateapp
    add_index :planning_applications, [:council_id, :date_received]
  end

  def self.down
    remove_index :planning_applications, :column => [:council_id, :date_received]
    add_index :planning_applications, [:date_received], :name => "dateapp"
    add_index :planning_applications, [:retrieved_at], :name => "datescr"
    add_index :planning_applications, [:lat, :lng, :retrieved_at], :name => "index_planning_applications_on_lat_and_long_and_retrieved_at", :unique => true
    add_index :planning_applications, :council_id
    remove_index :planning_applications, :column => [:council_id, :uid]
  end
end

class AddEpsg27700GeomToPlanningApplications < ActiveRecord::Migration
  def self.up
    add_column :alert_subscribers, :metres, :point, :srid => 27700
    add_column :hyperlocal_sites, :metres, :point, :srid => 27700
    add_column :planning_applications, :metres, :point, :srid => 27700
    add_column :postcodes, :metres, :point, :srid => 27700

    add_index :alert_subscribers, :metres, :spatial => true
    add_index :hyperlocal_sites, :metres, :spatial => true
    add_index :planning_applications, :metres, :spatial => true
    add_index :postcodes, :metres, :spatial => true

    # Run separately:
    #
    # UPDATE alert_subscribers SET metres = ST_Transform(geom, 27700);
    # UPDATE hyperlocal_sites SET metres = ST_Transform(geom, 27700);
    # UPDATE planning_applications SET metres = ST_Transform(geom, 27700);
    # UPDATE postcodes SET metres = ST_Transform(geom, 27700);
  end

  def self.down
    remove_column :alert_subscribers, :metres
    remove_column :hyperlocal_sites, :metres
    remove_column :planning_applications, :metres
    remove_column :postcodes, :metres
  end
end

class RemoveLimitsFromPlanningApplications < ActiveRecord::Migration
  def self.up
    # These take forever:
    #
    #change_column :planning_applications, :postcode, :string, :limit => nil
    #change_column :planning_applications, :decision, :string, :limit => nil
    #change_column :planning_applications, :application_type, :string, :limit => nil
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 259 WHERE attrelid = 'planning_applications'::regclass AND attname = 'postcode';"
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 259 WHERE attrelid = 'planning_applications'::regclass AND attname = 'decision';"
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 259 WHERE attrelid = 'planning_applications'::regclass AND attname = 'application_type';"
  end

  def self.down
    # These take forever:
    #
    #change_column :planning_applications, :postcode, :string, :limit => 10
    #change_column :planning_applications, :decision, :string, :limit => 64
    #change_column :planning_applications, :application_type, :string, :limit => 64
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 14 WHERE attrelid = 'planning_applications'::regclass AND attname = 'postcode';"
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 68 WHERE attrelid = 'planning_applications'::regclass AND attname = 'decision';"
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 68 WHERE attrelid = 'planning_applications'::regclass AND attname = 'application_type';"
  end
end

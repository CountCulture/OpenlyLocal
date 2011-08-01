class CreatePlanningApplications < ActiveRecord::Migration
  def self.up
    #NB Planning alerts table gets created by MySQL import from table based on planning alerts
    add_column :councils, :planning_email, :string
    # add_column :planning_applications, :applicant_name, :string
    # add_column :planning_applications, :applicant_address, :text
    # add_index :planning_applications, :council_id
    # add_index :planning_applications, [:lat, :lng]
    
  end

  def self.down
    # remove_index :planning_applications, [:lat, :lng]
    # remove_index :planning_applications, :council_id
    remove_column :councils, :planning_email
    # drop_table :planning_applications
  end
end

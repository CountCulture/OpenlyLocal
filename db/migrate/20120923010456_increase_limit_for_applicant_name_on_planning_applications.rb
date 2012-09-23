class IncreaseLimitForApplicantNameOnPlanningApplications < ActiveRecord::Migration
  def self.up
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 1028 WHERE attrelid = 'planning_applications'::regclass AND attname = 'applicant_name';"
  end

  def self.down
    PlanningApplication.connection.execute "UPDATE pg_attribute SET atttypmod = 259 WHERE attrelid = 'planning_applications'::regclass AND attname = 'applicant_name';"
  end
end

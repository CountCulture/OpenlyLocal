class AddAnnualAuditLetterToCouncils < ActiveRecord::Migration
  def self.up
    add_column :councils, :annual_audit_letter, :string
    add_column :police_authorities, :annual_audit_letter, :string
  end

  def self.down
    remove_column :councils, :annual_audit_letter
    remove_column :police_authorities, :annual_audit_letter
  end
end

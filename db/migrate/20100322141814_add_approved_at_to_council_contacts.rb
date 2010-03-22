class AddApprovedAtToCouncilContacts < ActiveRecord::Migration
  def self.up
    add_column :council_contacts, :approved, :datetime
  end

  def self.down
    remove_column :council_contacts, :approved
  end
end

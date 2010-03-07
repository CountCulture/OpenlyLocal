class AddPoliticalPartyIdToCandidates < ActiveRecord::Migration
  def self.up
    add_column :candidates, :political_party_id, :integer
  end

  def self.down
    remove_column :candidates, :political_party_id
  end
end

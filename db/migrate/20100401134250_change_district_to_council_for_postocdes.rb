class ChangeDistrictToCouncilForPostocdes < ActiveRecord::Migration
  def self.up
    rename_column :postcodes, :district_id, :council_id
  end

  def self.down
    # rename_column :postcodes, :council_id, :district_id
  end
end

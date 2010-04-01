class AddIndicesToPostcodes < ActiveRecord::Migration
  def self.up
    add_index :police_teams, :police_force_id
    add_index :hyperlocal_sites, :council_id
    add_index :wards, :police_team_id
    add_index :feed_entries, [:feed_owner_id, :feed_owner_type]
    add_index :twitter_accounts, [:user_id, :user_type]
    add_index :council_contacts, :council_id
    add_index :user_submissions, :member_id
    add_index :user_submissions, :council_id
    add_index :candidates, :poll_id
    add_index :candidates, :political_party_id
    add_index :candidates, :member_id
    add_index :polls, [:area_id, :area_type]
    add_index :police_officers, :police_team_id
    add_index :postcodes, :code
    add_index :postcodes, :ward_id
    add_index :postcodes, :council_id
    add_index :postcodes, :county_id
  end

  def self.down
    remove_index :police_teams, :police_force_id
    remove_index :hyperlocal_sites, :council_id
    remove_index :wards, :police_team_id
    remove_index :feed_entries, :column => [:feed_owner_id, :feed_owner_type]
    remove_index :twitter_accounts, :column => [:user_id, :user_type]
    remove_index :council_contacts, :council_id
    remove_index :user_submissions, :member_id
    remove_index :user_submissions, :council_id
    remove_index :candidates, :poll_id
    remove_index :candidates, :political_party_id
    remove_index :candidates, :member_id
    remove_index :polls, :column => [:area_id, :area_type]
    remove_index :police_officers, :police_team_id
    remove_index :postcodes, :code
    remove_index :postcodes, :ward_id
    remove_index :postcodes, :council_id
    remove_index :postcodes, :county_id
  end
end

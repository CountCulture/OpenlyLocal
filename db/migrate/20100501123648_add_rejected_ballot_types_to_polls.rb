class AddRejectedBallotTypesToPolls < ActiveRecord::Migration
  def self.up
    add_column :polls, :ballots_missing_official_mark, :integer
    add_column :polls, :ballots_with_too_many_candidates_chosen, :integer
    add_column :polls, :ballots_with_identifiable_voter, :integer
    add_column :polls, :ballots_void_for_uncertainty, :integer
  end

  def self.down
    remove_column :polls, :ballots_void_for_uncertainty
    remove_column :polls, :ballots_with_identifiable_voter
    remove_column :polls, :ballots_with_too_many_candidates_chosen
    remove_column :polls, :too_many_candidates_ballots
  end
end

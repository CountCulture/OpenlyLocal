class Poll < ActiveRecord::Base
  BallotRejectedCategories = %w(ballots_missing_official_mark ballots_with_too_many_candidates_chosen ballots_with_identifiable_voter ballots_void_for_uncertainty)
  belongs_to :area, :polymorphic => true
  has_many :candidacies, :dependent => :destroy
  has_many :related_articles, :as => :subject
  validates_presence_of :date_held, :area_id, :area_type, :position
  
  def self.from_open_election_data(polls=[])
    polls.collect do |poll_info|
      if area = Ward.find_from_resource_uri(poll_info[:area])
      poll = area.polls.find_or_initialize_by_date_held_and_position( :date_held => poll_info[:date], :position => 'Member')
      poll.update_attributes( :electorate => poll_info[:electorate], 
                              :ballots_issued => poll_info[:ballots_issued],
                              :source => poll_info[:source], 
                              :uncontested => poll_info[:uncontested] == 'true' )
      poll_info[:candidacies].each do |candidacy_info|
        name = NameParser.parse(candidacy_info[:name])
        candidacy = poll.candidacies.find_or_initialize_by_first_name_and_last_name( :first_name => candidacy_info[:given_name]||name[:first_name], 
                                                                                     :last_name => candidacy_info[:family_name]||name[:last_name])
        candidacy.update_attributes( :elected => candidacy_info[:elected] == 'true',
                                     :votes => candidacy_info[:votes],
                                     :political_party => PoliticalParty.find_from_resource_uri(candidacy_info[:party]) )
      end
      poll
      end
    end
  end
  
  def rejected_ballot_details?
    (ballots_rejected.to_i > 0) && (BallotRejectedCategories.sum{ |cat| self.send(cat).to_i  } > 0)
  end
  
  def status
    uncontested? ? 'uncontested' : nil
  end
  
  def title
    date_held.to_s(:event_date)
  end
  
  def turnout
    return unless ballots_issued&&electorate
    ballots_issued.to_f/electorate.to_f
  end
end

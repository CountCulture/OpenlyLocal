class Poll < ActiveRecord::Base
  belongs_to :area, :polymorphic => true
  has_many :candidacies
  validates_presence_of :date_held, :area_id, :area_type, :position
  
  def title
    date_held.to_s(:event_date)
  end
  
  def turnout
    return unless ballots_issued&&electorate
    ballots_issued.to_f/electorate.to_f
  end
  
  def self.from_open_election_data(polls=[])
    polls.each do |poll_info|
      area = Ward.find_from_resource_uri(poll_info[:area])
      poll = area.polls.find_or_create_by_date_held( :date_held => poll_info[:date], 
                                                     :position => 'Member', 
                                                     :electorate => poll_info[:electorate], 
                                                     :ballots_issued => poll_info[:ballots_issued],
                                                     :source => poll_info[:source], 
                                                     :uncontested => poll_info[:uncontested] )
      poll_info[:candidacies].each do |candidacy_info|
        name = NameParser.parse(candidacy_info[:name])
        poll.candidacies.find_or_create_by_first_name_and_last_name( :first_name => candidacy_info[:first_name]||name[:first_name], 
                                                                     :last_name => candidacy_info[:last_name]||name[:last_name], 
                                                                     :votes => candidacy_info[:votes],
                                                                     :political_party => PoliticalParty.find_from_resource_uri(candidacy_info[:party]))
      end
    end
  end
end

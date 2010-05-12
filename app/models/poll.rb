class Poll < ActiveRecord::Base
  BallotRejectedCategories = %w(ballots_missing_official_mark ballots_with_too_many_candidates_chosen ballots_with_identifiable_voter ballots_void_for_uncertainty)
  CsvFields = %w(id area_resource_uri area_title area_type position electorate ballots_issued ballots_rejected postal_votes uncontested source)
  belongs_to :area, :polymorphic => true
  has_many :candidacies, :dependent => :destroy
  has_many :related_articles, :as => :subject
  named_scope :associated_with_council, lambda { |council| council ? { :joins => 'INNER JOIN wards', 
                                                                       :group => 'polls.id',
                                                                       :conditions => ["(wards.council_id = ?) AND ((polls.area_id = wards.id AND polls.area_type ='Ward') OR (polls.area_id = ? AND polls.area_type ='Council'))", council.id, council.id],
                                                                       :order => 'polls.date_held DESC, polls.created_at DESC' } : {} }
  
  validates_presence_of :date_held, :area_id, :area_type, :position
  delegate :resource_uri, :title, :to => :area, :prefix => true
  
  def self.from_open_election_data(polls=[], options={})
    raise ArgumentError, "No council supplied for Poll#from_open_election_data" unless council = options[:council]
    polls.collect do |poll_info|
      if (area = Ward.find_from_resource_uri(poll_info[:area])) && (area.council == council)
        date_held = poll_info[:date] || poll_info[:uri].to_s.scan(/openelectiondata.org\/id\/polls\/[^\/]+\/([\d-]+)/).to_s
        poll = area.polls.find_or_initialize_by_date_held_and_position( :date_held => date_held, :position => 'Member')
        poll.update_attributes( :electorate => poll_info[:electorate], 
                                :ballots_issued => poll_info[:ballots_issued],
                                :ballots_rejected => poll_info[:ballots_rejected],
                                :source => poll_info[:source], 
                                :uncontested => poll_info[:uncontested] == 'true' )
        poll_info[:candidacies].each do |candidacy_info|
          name = NameParser.parse(candidacy_info[:name]) || {}
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
  
  def self.to_csv
    poll_array = [CsvFields] + all.collect { |p| CsvFields.collect{ |f| p.send(f) } }
    poll_array.collect { |r| FasterCSV.generate_line(r) }.join
  end
  
  def extended_title
    "#{position} for #{area.title}, #{title}"
  end
  
  def rejected_ballot_details?
    (ballots_rejected.to_i > 0) && (BallotRejectedCategories.sum{ |cat| self.send(cat).to_i  } > 0)
  end
  
  def resource_uri
    "http://#{DefaultDomain}/id/polls/#{id}"
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

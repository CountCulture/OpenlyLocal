class Candidate < ActiveRecord::Base
  belongs_to :election
  validates_presence_of :election_id, :last_name
  delegate :ward, :to => :election
end

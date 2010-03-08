class Candidate < ActiveRecord::Base
  belongs_to :poll
  belongs_to :political_party
  validates_presence_of :poll_id, :last_name
  delegate :area, :to => :poll
  
  def party_name
    political_party ? political_party.name : party
  end
  
  def status
    elected ? 'elected' : nil
  end
end

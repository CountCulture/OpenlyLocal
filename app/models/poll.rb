class Poll < ActiveRecord::Base
  belongs_to :area, :polymorphic => true
  has_many :candidates
  validates_presence_of :date_held, :area_id, :area_type, :position
  
  def title
    date_held.to_s(:event_date)
  end
  
  def turnout
    return unless ballots_issued&&electorate
    ballots_issued.to_f/electorate.to_f
  end
end

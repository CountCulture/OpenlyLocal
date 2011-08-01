class PlanningApplication < ActiveRecord::Base
  belongs_to :council
  validates_presence_of :council_id
  
  def title
    "Planning Application #{council_reference}" + (address ? ", #{address[0..30]}..." : '')
  end
end

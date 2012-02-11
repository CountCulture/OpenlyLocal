# This class is basically a wrapper around Charity methods. We need to do this as the queued
# items may be put there by OpenCharities (which uses Delayed::Job 3) but run by OpenlyLocal 
# (which uses Delayed::Job 2)
class CharityWorker
  attr_reader :charity_id, :delayed_meth
    
  def initialize(charity, meth)
    @charity_id = charity.id
    @delayed_meth = meth
  end
    
  def perform
    Charity.find(charity_id).send(delayed_meth)
  end

end
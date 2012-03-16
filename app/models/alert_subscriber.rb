class AlertSubscriber < ActiveRecord::Base
  validates_presence_of :email, :postcode
  validates_uniqueness_of :email
  
  def send_planning_alert(planning_application)
    
  end
end

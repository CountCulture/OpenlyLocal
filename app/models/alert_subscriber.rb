class AlertSubscriber < ActiveRecord::Base
  validates_presence_of :email, :postcode
  validates_uniqueness_of :email
  before_create :set_confirmation_code
  
  def self.confirm_from_email_and_code(email_address, conf_code)
    if subscriber = find_by_email_and_confirmation_code(email_address, conf_code)
      subscriber.update_attribute(:confirmed, true)
    else
      logger.info "User with email #{email_address} failed to confirm using confirmation_code #{conf_code}"
      false
    end
  end
  
  def self.unsubscribe_user_from_email_and_token(email, given_unsubscribe_token)
    if unsubscribe_token(email) == given_unsubscribe_token
      subscriber = find_by_email(email)
      subscriber&&subscriber.destroy
    end
  end
  
  def self.unsubscribe_token(email_address)
    Digest::SHA1.hexdigest( [email_address, UNSUBSCRIBE_SECRET_KEY].collect{|e| Digest::SHA1.hexdigest(e)}.join)
  end
  
  def send_planning_alert(planning_application)

  end
  
  def unsubscribe_token
    self.class.unsubscribe_token(email)
  end
  
  private
  def set_confirmation_code
    self[:confirmation_code] = SecureRandom.hex(32)
  end
    
end

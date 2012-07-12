class AlertSubscriber < ActiveRecord::Base
  attr_accessible :email, :postcode_text, :distance

  belongs_to :postcode
  validates_presence_of :email, :postcode_text, :distance, :postcode_id
  validates_uniqueness_of :email
  validates_inclusion_of :distance, :in => [0.2, 0.8, 2]
  before_validation :set_postcode_from_text
  before_create :set_confirmation_code, :set_geo_data_from_postcode_text
  after_create :send_confirmation_email
  after_destroy :send_unsubscribe_confirmation_email

  named_scope :confirmed, :conditions => {:confirmed => true}
  named_scope :geocoded, :conditions => 'bottom_left_lat IS NOT NULL'
  named_scope :contains, lambda { |lat,lng|
    {
      :conditions => [
        'bottom_left_lat <= ? AND bottom_left_lng <= ? AND top_right_lat >= ? AND top_right_lng >= ?',
        lat, lng, lat, lng,
      ],
    }
  }

  def self.confirm_from_email_and_code(email_address, conf_code)
    if subscriber = find_by_email_and_confirmation_code(email_address, conf_code)
      subscriber.update_attribute(:confirmed, true)
    else
      logger.info "User with email #{email_address} failed to confirm using confirmation_code #{conf_code}"
      false
    end
  end
  
  def self.bounding_box_from_postcode_and_distance(postcode, distance)
    Geokit::Bounds.from_point_and_radius(postcode, distance) if postcode
  end
  
  def self.unsubscribe_user_from_email_and_token(email, given_unsubscribe_token)
    if unsubscribe_token(email) == given_unsubscribe_token
      subscriber = find_by_email(email)
      subscriber && subscriber.destroy
    end
  end
  
  def self.unsubscribe_token(email_address)
    Digest::SHA1.hexdigest( [email_address, UNSUBSCRIBE_SECRET_KEY].collect{|e| Digest::SHA1.hexdigest(e)}.join)
  end
  
  def send_planning_alert(planning_application)
    AlertMailer.deliver_planning_alert!(:planning_application => planning_application, :subscriber => self)
  end
  
  def unsubscribe_token
    self.class.unsubscribe_token(email)
  end
  
  private
  def set_postcode_from_text
    self.postcode = Postcode.find_from_messy_code(postcode_text)
  end

  def set_confirmation_code
    self[:confirmation_code] = SecureRandom.hex(32)
  end
  
  def set_geo_data_from_postcode_text
    if bounding_box = self.class.bounding_box_from_postcode_and_distance(postcode, distance)
      self.bottom_left_lat = bounding_box.sw.lat
      self.bottom_left_lng = bounding_box.sw.lng
      self.top_right_lat   = bounding_box.ne.lat
      self.top_right_lng   = bounding_box.ne.lng
    end
  end
  
  def send_confirmation_email
    AlertMailer.deliver_confirmation!(self)
  end

  def send_unsubscribe_confirmation_email
    AlertMailer.deliver_unsubscribe_confirmation!(self)
  end
end

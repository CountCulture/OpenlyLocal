class Address < ActiveRecord::Base
  belongs_to :addressee, :polymorphic => true
  validates_presence_of :addressee_type, :addressee_id
  after_save :queue_for_geocoding


  def in_full
    [street_address, locality, postal_code].select{|a| !a.blank?}.join(', ')
  end
  
  def in_full=(raw_addr)
    self.attributes = AddressUtilities::Parser.parse(raw_addr)
  end
  
  def perform
    location = Geokit::LatLng.normalize(in_full)
    update_attributes(:lat => location.lat, :lng => location.lng)
  rescue Geokit::Geocoders::GeocodeError
    logger.error { "Error geocoding address #{in_full} for #{self.inspect}" }
  end
  
  private
  def queue_for_geocoding
    self.delay.perform if lat.nil? #don't geocode if already got address
  end
end

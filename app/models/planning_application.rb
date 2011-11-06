class PlanningApplication < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :council
  validates_presence_of :council_id, :uid
  alias_attribute :council_reference, :uid
  serialize :other_attributes
  acts_as_mappable
  before_save :update_lat_lng
  named_scope :stale, lambda { { :conditions => ["retrieved_at IS NULL OR retrieved_at < ?", 7.days.ago] } }
  
  def address=(raw_address)
    cleaned_up_address = raw_address.blank? ? raw_address : raw_address.gsub("\r", "\n").gsub(/\s{2,}/,' ').strip
    self[:address] = cleaned_up_address
    parsed_postcode = cleaned_up_address&&cleaned_up_address.scan(Address::UKPostcodeRegex).first
    self[:postcode] = parsed_postcode unless postcode_changed? # if already changed it's prob been explicitly set
  end
  
  def google_map_magnification
    13
  end
  
  def inferred_lat_lng
    return unless matched_code = postcode&&Postcode.find_from_messy_code(postcode)
    [matched_code.lat, matched_code.lng]
  end
  
  def title
    "Planning Application #{uid}" + (address.blank? ? '' : ", #{address[0..30]}...")
  end
  
  private
  def update_lat_lng
    i_lat_lng = [inferred_lat_lng].flatten # so gives empty array if nil
    self[:lat] = i_lat_lng[0] unless self[:lat] && self.lat_changed?
    self[:lng] = i_lat_lng[1] unless self[:lng] && self.lng_changed?
  end
end

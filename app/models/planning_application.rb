class PlanningApplication < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :council
  validates_presence_of :council_id, :uid
  alias_attribute :council_reference, :uid
  serialize :other_attributes
  named_scope :stale, lambda { { :conditions => ["retrieved_at IS NULL OR retrieved_at < ?", 7.days.ago] } }
  
  def address=(raw_address)
    cleaned_up_address = raw_address.blank? ? raw_address : raw_address.gsub("\r", "\n").gsub(/\s{2,}/,' ').strip
    self[:address] = cleaned_up_address
    parsed_postcode = cleaned_up_address&&cleaned_up_address.scan(Address::UKPostcodeRegex).first
    self[:postcode] = parsed_postcode unless postcode_changed? # if already changed it's prob been explicitly set
  end
  
  def title
    "Planning Application #{uid}" + (address.blank? ? '' : ", #{address[0..30]}...")
  end
end

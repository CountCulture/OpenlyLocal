class PlanningApplication < ActiveRecord::Base
  include ScrapedModel::Base
  extend Resque::Plugins::LockTimeout
  belongs_to :council
  validates_presence_of :council_id, :uid
  validates_uniqueness_of :uid, :scope => :council_id
  alias_attribute :council_reference, :uid
  serialize :other_attributes
  acts_as_mappable :default_units => :kms
  before_save :update_lat_lng
  before_save :update_start_date
  after_save :queue_for_sending_alerts_if_relevant
  before_create :set_default_value_for_bitwise_flag
  after_create :queue_for_updating_info
  alias_method :old_to_xml, :to_xml
  delegate :openlylocal_url, :to => :council, :prefix => true
  delegate :name, :to => :council, :prefix => true
  STATUS_TYPES_AND_ALIASES = [
                              ['approved', 'permitted'],
                              ['pending'],
                              ['refused', 'refusal', 'rejected'],
                              ['invalid'],
                              ['withdrawn']
                              ]
  @queue = :planning_applications

  CSV_MAPPINGS = [[:openlylocal_id, :id],
                 [:openlylocal_url],
                 [:address, :formatted_address],
                 [:postcode],
                 [:lat],
                 [:lng],
                 [:updated_at],
                 [:retrieved_at],
                 [:description],
                 [:decision],
                 [:status],
                 [:date_received],
                 [:date_validated],
                 [:start_date],
                 [:council_name],
                 [:council_openlylocal_url],
                 [:url],
                 [:uid]]

  # The stale strategy for planning_applications is quite complex, due to the way planning applications change over time:
  # First of all planning_applications that have no retrieved_at timestamp are considered stale, as we've not got any 
  # details about them.
  # Then applications that are younger than 3 months ago are considered stale, but returned oldest first (based on retrieed_at) 
  # In addition, some info scrapers require several URLs to be fetched and parsed. This is done through the use of the 
  # bitwise_flag. This attribute is only used by info scrapers who have parsers with :bitwise_flag in the attribute_parser
  # 
  
  named_scope :stale, lambda { { :conditions => [ "retrieved_at IS NULL OR retrieved_at > ?", 3.months.ago], 
                                 :limit => 100, 
                                 :order => 'retrieved_at' } }
  
  named_scope :with_details, { :conditions => "retrieved_at IS NOT NULL" } 
  named_scope :recent, lambda { { :conditions => [ "start_date > ?", 2.weeks.ago],
                                  :limit => 5, 
                                  :order => 'start_date DESC' } }
  

  named_scope :with_clear_bitwise_flag, lambda { |bitwise_number| { :conditions => ["bitwise_flag & ? = 0", bitwise_number]}}

  def self.perform(pa_id, method = nil)
    find(pa_id).update_info
  rescue Scraper::ScraperError => e
    logger.error "Exception (#{e.inspect}) updating info for PlanningApplication with id #{pa_id}"
    Resque.enqueue_to(:planning_application_exceptions, PlanningApplication, pa_id)
  end
  
  def address=(raw_address)
    cleaned_up_address = raw_address.blank? ? raw_address : raw_address.gsub("\r", "\n").gsub(/\s{2,}/,' ').strip
    self[:address] = cleaned_up_address
    parsed_postcode = NameParser.extract_uk_postcode(cleaned_up_address)
    self[:postcode] = parsed_postcode unless postcode_changed? # if already changed it's prob been explicitly set
  end
  
  # status is used by ScrapedModel mixin to show status of AR record so we make :status attribute available through this method
  def application_status
    self[:status]
  end
  
  # overload normal attribute setter. This sets the bitwise_flag attribute using 
  def bitwise_flag=(bw_int)
    return unless bw_int
    new_bitwise_flag = (bitwise_flag||0) | bw_int
    self[:bitwise_flag] = new_bitwise_flag == 7 ? 0 : new_bitwise_flag
  end
  
  def company_name
    
  end
  
  def self.csv_headings
    CSV_MAPPINGS.map(&:first)
  end

  def csv_data
    CSV_MAPPINGS.collect do |m|
      val = self.send(m.last)
      case val
      when Time
        val.iso8601
      when Date
        val.to_s(:db)
      else
        val
      end
    end
  end
  
  def date_received
    date = TitleNormaliser.normalise_uk_date(other_attributes && other_attributes[:date_received])
    date ? date : nil
  end
  
  def date_validated
    date = TitleNormaliser.normalise_uk_date(other_attributes && other_attributes[:date_validated])
    date ? date : nil
  end
  
  def start_date=(raw_date)
    self[:start_date] = TitleNormaliser.normalise_uk_date(raw_date)
  end
  
  # overwrite default behaviour
  def self.find_all_existing(params={})
    []
  end
  
  def formatted_address
    address.blank? ? nil : address.gsub(/\n+/, ', ')
  end
  
  def google_map_magnification
    13
  end
  
  def inferred_lat_lng
    return unless matched_code = postcode&&Postcode.find_from_messy_code(postcode)
    [matched_code.lat, matched_code.lng]
  end
  
  def matching_subscribers
    []
  end
  
  # cleean up so we can get consistency across councils
  def normalised_application_status
    return if application_status.blank?
    STATUS_TYPES_AND_ALIASES.detect{ |s_and_a| s_and_a.any?{ |matcher| application_status.match(Regexp.new(matcher, true)) } }.try(:first)
  end
  
  def queue_for_sending_alerts
    return unless start_date && (start_date > 1.month.ago.to_date)
    Resque.enqueue_to(:planning_application_alerts, PlanningApplication, self.id, :send_alerts)
  end
  
  def send_alerts
    matching_subscribers.each{ |subscriber| subscriber.send_planning_alert(self) }
  end
  
  def title
    "Planning Application #{uid}" + (address.blank? ? '' : ", #{address[0..30]}...")
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:only => [:id, :uid, :address, :lat, :lng, :postcode, :updated_at, :retrieved_at, :description, :decision, :status, :url, :application_type, :comment_url], :methods => [:openlylocal_url]}.merge(options), &block)
  end
  
  def to_detailed_xml(options={})
    # includes = {:members => {:only => [:id, :first_name, :last_name, :party, :url]}, :wards => {}, :twitter_account => {}}
    to_xml({:include => [:council]}.merge(options)) do |builder|
      builder<<council.to_xml(:skip_instruct => true, :root => "council", :only => [ :id, :title, :url ], :methods => [:openlylocal_url])
      builder<<other_attributes.to_xml(:skip_instruct => true, :root => "other_attributes") if other_attributes?
    end
  end

  protected
  # overwrite default behaviour
  def self.record_not_found_behaviour(params)
    logger.debug "****** record_not_found: params[:uid] = #{params[:uid]}, params[:council]= #{params[:council]}"
    # HACK ALERT!! Not sure why but params['uid'] not found on prodcution server, params[:uid] not found on development!
    pa = params[:council].planning_applications.find_or_initialize_by_uid(params['uid']||params[:uid])
    pa.attributes = params
    logger.debug "****** record_not_found: Planning Application: #{pa.inspect}"
    pa
  end
  
  
  private
  def queue_for_sending_alerts_if_relevant
    queue_for_sending_alerts unless self.changes["lat"].blank? || self.changes["lng"].blank?
  end
  
  def queue_for_updating_info
    Resque.enqueue_to(:planning_applications_after_create, PlanningApplication, self.id)
  end
  
  def update_lat_lng
    i_lat_lng = [inferred_lat_lng].flatten # so gives empty array if nil
    self[:lat] = i_lat_lng[0] unless self[:lat] && self.lat_changed?
    self[:lng] = i_lat_lng[1] unless self[:lng] && self.lng_changed?
  end
  
  def update_start_date
    case date_received
    when nil
      self[:start_date] ||= date_validated if date_validated
    else
      self[:start_date] ||= date_received
    end
    true
  end
  
  def set_default_value_for_bitwise_flag
    self[:bitwise_flag] ||= 0
  end
end

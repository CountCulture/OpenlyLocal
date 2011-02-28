class Charity < ActiveRecord::Base

  has_many :classification_links, :as => :classified, :uniq => true
  has_many :classifications, :through => :classification_links
  has_many :charity_annual_reports
  belongs_to :company, :primary_key => "company_number", :foreign_key => "normalised_company_number"
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  include AddressUtilities::Base
  include ResourceMethods
  include SocialNetworkingUtilities::Base
  serialize :financial_breakdown
  serialize :accounts
  serialize :trustees
  serialize :other_names
  
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
  validates_uniqueness_of :company_number, :allow_nil => true
  validates_uniqueness_of :normalised_company_number, :allow_nil => true
  before_save :normalise_title
  alias_attribute :url, :website  
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising charity titles
  def self.normalise_title(raw_title)
    return if raw_title.blank?
    TitleNormaliser.normalise_title(raw_title.gsub(/\A\s*the\s/i, ''))
  end
  
  def self.add_new_charities(options={})
    puts "***About to get new charities from Charity Register" # usually run from cron job, so this will get added to cron log
    new_charities = CharityUtilities::Client.new.get_recent_charities(options[:start_date], options[:end_date]).collect do |charity_info|
      charity = Charity.create(charity_info)
      begin
        charity.update_info unless charity.new_record? # update info only if it's saved
      rescue Exception, Timeout::Error => e
        logger.error { "Exception updating charity #{charity.title} (#{charity.charity_number})" }
      end
      charity
    end
  end
  
  def accounts=(accounts_data)
    self[:accounts] = accounts_data
    return accounts_data if accounts_data.blank?
    [:accounts_date, :income, :spending].each do |a|
      self[a] = accounts.first[a]
    end
    accounts_data
  end
  
  def charity_commission_url
    "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{charity_number}&SubsidiaryNumber=0"
  end
  
  def company_number=(raw_number)
    self[:company_number] = raw_number
    self[:normalised_company_number] = Company.normalise_company_number(raw_number)
  end
  
  def extended_title
    "#{title} (charity number #{charity_number}" + (status ? ", #{status})" : ")")
  end
  
  def resource_uri
    "http://opencharities.org/id/charities/#{charity_number}"
  end
  
  def status
    'removed' if date_removed?
  end
  
  def update_from_charity_register
    attribs = CharityUtilities::Client.new(:charity_number => charity_number).get_details
    self.last_checked = Time.now
    update_attributes(attribs.delete_if{ |k,v| v.blank?||!self.respond_to?(k) }) #delete unknown attribs which may be scraped but not yet added to charity
  end
  
  def update_info
    return unless update_from_charity_register
    update_social_networking_details_from_website
    true
  end
  
  def website=(raw_url)
    self[:website] = TitleNormaliser.normalise_url(raw_url)
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
end

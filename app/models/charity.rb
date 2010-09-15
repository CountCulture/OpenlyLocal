class Charity < ActiveRecord::Base
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  include SpendingStatUtilities::Base
  include AddressMethods
  include ResourceMethods
  serialize :financial_breakdown
  serialize :accounts
  serialize :trustees
  serialize :other_names
  
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
  before_save :normalise_title
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising charity titles
  def self.normalise_title(raw_title)
    return if raw_title.blank?
    TitleNormaliser.normalise_title(raw_title.gsub(/\A\s*the\s/i, ''))
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
  
  def update_from_charity_register
    attribs = CharityUtilities::Client.new(:charity_number => charity_number).get_details
    self.last_checked = Time.now
    update_attributes(attribs.delete_if{ |k,v| v.blank?||!self.respond_to?(k) }) #delete unknown attribs which may be scraped but not yet added to charity
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
end

class Charity < ActiveRecord::Base
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  include SpendingStatUtilities::Base
  include AddressMethods
  include ResourceMethods
  
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
  before_save :normalise_title
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising charity titles
  def self.normalise_title(raw_title)
    return if raw_title.blank?
    TitleNormaliser.normalise_title(raw_title.gsub(/\A\s*the\s/i, ''))
  end
  
  def charity_commission_url
    "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{charity_number}&SubsidiaryNumber=0"
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
end

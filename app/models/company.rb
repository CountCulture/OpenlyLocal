class Company < ActiveRecord::Base
  has_many :suppliers
  validates_presence_of :title
  before_save :normalise_title
  
  # matches normalised version of given title with
  def self.matches_title(raw_title)
    first(:conditions => {:normalised_title => normalise_title(raw_title)})
  end
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising supplier titles
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_company_title(raw_title)
  end
  
  # returns companies_house url via companies open house redirect
  def companies_house_url
    "http://companiesopen.org/uk/#{company_number}/companies_house" if company_number?
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
end

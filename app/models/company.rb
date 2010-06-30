class Company < ActiveRecord::Base
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  validates_presence_of :company_number
  validates_uniqueness_of :company_number
  before_save :normalise_title
  
  # matches normalised version of given title with
  def self.matches_title(raw_title)
    first(:conditions => {:normalised_title => normalise_title(raw_title)})
  end
  
  def self.match_or_create_from_company_number(number_string)
    find_or_create_by_company_number(normalise_company_number(number_string))
  end
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising supplier titles
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_company_title(raw_title)
  end
  
  # returns companies_house url via companies open house redirect
  def companies_house_url
    "http://companiesopen.org/uk/#{company_number}/companies_house" if company_number?
  end
  
  def to_param
    self[:title] ? "#{id}-#{title.parameterize}" : id.to_s
  end
  
  def title
    self[:title] || "Company number #{company_number}"
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title) unless self[:title].blank?
    true # always save
  end
  
  def self.normalise_company_number(raw_number)
    sprintf("%08d", raw_number.to_i)
  end
end

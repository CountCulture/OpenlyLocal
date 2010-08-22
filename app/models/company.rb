class Company < ActiveRecord::Base
  include AddressMethods
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  validates_uniqueness_of :company_number, :vat_number, :allow_blank => true
  before_save :normalise_title
  
  def validate
    errors.add_to_base('Either the company number or vat number must be present') unless (company_number? || vat_number?)
  end
  
  # matches normalised version of given title with
  def self.from_title(raw_title)
    if existing_company = first(:conditions => {:normalised_title => normalise_title(raw_title)})
      return existing_company 
    elsif company_info = CompanyUtilities::Client.new.company_from_name(raw_title)
      Company.create!(company_info)
    end
  end
  
  def self.match_or_create(params={})
    params[:company_number] = normalise_company_number(params[:company_number]) if params[:company_number] # use normalised version of company number
    company = params[:company_number].blank? ? (params[:vat_number].blank? ? Company.new(params) : find_or_create_by_vat_number(params)) : find_or_create_by_company_number(params) 
    Delayed::Job.enqueue(company) if company.instance_variable_get(:@new_record_before_save)
    company
  end
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising company titles
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_company_title(raw_title.gsub(/\s?&\s?/, ' and '))
  end
  
  def self.normalise_company_number(raw_number)
    raw_number.blank? ? nil : sprintf("%08d", raw_number.to_i)
  end
  
  # returns companies_house url via companies open house redirect
  def companies_house_url
    "http://companiesopen.org/uk/#{company_number}/companies_house" if company_number?
  end
  
  # alias populate_basic_info as perform so that this gets run when doing delayed_job on a company
  def perform
    populate_basic_info
  end
  
  def populate_basic_info
    if company_number
      basic_info = CompanyUtilities::Client.new.get_basic_info(company_number)
    else
      basic_info = CompanyUtilities::Client.new.get_vat_info(vat_number)
    end
    update_attributes(basic_info)
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
  
end

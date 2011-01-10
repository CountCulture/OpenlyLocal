class Company < ActiveRecord::Base
  include AddressMethods
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  validates_presence_of :title, :on => :create # note initially we have some companies with company number but no title
  validates_uniqueness_of :company_number, :allow_blank => true
  validates_uniqueness_of :vat_number, :scope => :company_number, :allow_blank => true
  before_save :normalise_title
  after_create :add_to_queue_for_getting_more_info
  serialize :sic_codes
  serialize :previous_names
  
  def validate
    errors.add_to_base('Either the company number or vat number must be present') unless (company_number? || vat_number?)
  end
  
  # matches normalised version of given title with
  def self.from_title(raw_title, options={})
    if existing_company = first(:conditions => {:normalised_title => normalise_title(raw_title)})
      return existing_company 
    elsif company_info = CompanyUtilities::Client.new.find_company_by_name(raw_title)
      existing_company = Company.find_by_company_number(company_info[:company_number])
      return existing_company if existing_company
      options[:no_create] ? company_info : Company.create(company_info) #we may be returned company that has slightly diff name  but same company_number
    end
  end
  
  def self.match_or_create(params={})
    params[:company_number] = normalise_company_number(params[:company_number]) if params[:company_number] # use normalised version of company number
    company = params[:company_number].blank? ? (params[:vat_number].blank? ? Company.new(params) : find_or_create_by_vat_number(params)) : find_or_create_by_company_number(params) 
    # company = params[:company_number].blank? ? Company.new(params) : find_or_create_by_company_number(params) 
    company
  end
  
  def self.probable_company?(name)
    return if name.blank?
    name.gsub('.', '').match(/\bLtd|\bLimited|\bplc|\bllp|\bcompany/i)
  end
  
  # ScrapedModel module isn't mixed in
  def self.normalise_title(raw_title)
    return if raw_title.blank?
    TitleNormaliser.normalise_company_title(raw_title)
  end
  
  def self.normalise_company_number(raw_number)
    return nil if raw_number.blank?
    raw_number.to_s.match(/[A-Z]/) ? raw_number : sprintf("%08d", raw_number.to_i)
  end
  
  # returns opencorporates url
  def opencorporates_url
    "http://opencorporates.com/uk/#{company_number}" if company_number?
  end
  
  # alias populate_basic_info as perform so that this gets run when doing delayed_job on a company
  def perform
    populate_basic_info
  end
  
  def populate_basic_info
    if company_number
      basic_info = CompanyUtilities::Client.new.company_details_for(company_number)
      update_attributes(basic_info)
    else
      return unless basic_info = CompanyUtilities::Client.new.get_vat_info(vat_number)
      basic_info_or_payee = self.class.from_title(basic_info[:title], :no_create => true) || basic_info
      if basic_info_or_payee.is_a?(Hash) 
        update_attributes(basic_info_or_payee)
      else #it's an existing company, charity, entity etc
        basic_info_or_payee.update_attribute(:vat_number, vat_number)
        supplying_relationships.each{ |s| s.update_attribute(:payee, basic_info_or_payee) }
        self.destroy
      end 
    end
  end
    
  def resource_uri
    "http://opencorporates.com/id/companies/uk/#{company_number}"
  end
  
  def to_param
    self[:title] ? "#{id}-#{title.parameterize}" : id.to_s
  end
  
  # def title
  #   self[:title] || (company_number? ? "Company number #{company_number}" : "Company with VAT number #{vat_number}")
  # end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
    self.company_number = self.class.normalise_company_number(company_number) unless self[:company_number].blank?
    true # always save
  end
  
  def add_to_queue_for_getting_more_info
    Delayed::Job.enqueue(self)
  end
  
end

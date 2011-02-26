class Company < ActiveRecord::Base
  include AddressMethods
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  
  has_one :charity, :primary_key => "company_number", :foreign_key => "normalised_company_number"
  
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
  
  def self.calculated_spending_data
    res = {}
    res[:total_received_from_councils] = SpendingStat.sum(:total_received_from_councils, :conditions => "spending_stats.organisation_type = 'Company'")
    res[:transaction_count] = FinancialTransaction.count(:joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council' AND suppliers.payee_type = 'Company'")
    res[:company_count] = Company.count(:joins => :supplying_relationships, :conditions => 'suppliers.organisation_type = "Council"')
    res[:largest_transactions] = FinancialTransaction.all(:order => 'value DESC', :limit => 20, :joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council' AND suppliers.payee_type = 'Company'").collect(&:id)
    res[:largest_companies] = Company.all(:joins => :spending_stat, :order => 'total_received_from_councils DESC', :limit => 20).collect(&:id)
    res[:company_type_breakdown] = Company.count(:group => 'company_type', :conditions=>'company_number IS NOT NULL AND suppliers.organisation_type = "Council"', :joins => :supplying_relationships)
    res
  end
  
  # matches normalised version of given title with
  def self.from_title(raw_title, options={})
    company = first(:conditions => {:normalised_title => normalise_title(raw_title)})
    if !company && company_info = CompanyUtilities::Client.new.find_company_by_name(raw_title)
      company = Company.find_by_company_number(company_info[:company_number])
      # return existing_company if existing_company
      company = options[:no_create] ? company_info : Company.create(company_info) unless company
      # we may be returned company that has slightly diff name  but same company_number
    end
    # return associated charity if there is one, as we really want association to be with the charity, not the company
    company.is_a?(Company) && company.charity ? company.charity : company
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
  
  def council_spending_breakdown
    suppliers = supplying_relationships
    suppliers.group_by(&:organisation_id).collect do |council_id, sups|
      {:council_id => council_id}
    end
  end
  
  def extended_title
    details = [company_number, status].delete_if(&:blank?)
    details.empty? ? title : "#{title} (#{details.join(', ')})" 
  end
  
  # returns opencorporates url
  def opencorporates_url
    "http://opencorporates.com/companies/uk/#{company_number}" if company_number?
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

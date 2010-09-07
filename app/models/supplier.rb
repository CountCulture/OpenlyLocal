class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  has_many :financial_transactions, :order => 'date', :dependent => :destroy
  after_create :queue_for_matching_with_payee
  include SpendingStatUtilities::Base
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  named_scope :unmatched, :conditions => {:payee_id => nil}
  named_scope :filter_by, lambda { |filter_hash| filter_hash[:name] ? 
                                  { :conditions => ["name LIKE ?", "%#{filter_hash[:name]}%"] } : 
                                  {} }

  alias_attribute :title, :name
  
  def validate
    errors.add_to_base('Either a name or uid is required') if name.blank? && uid.blank?
  end
  
  # Finds supplier given params, one of which must be :organisation (and that organisation 
  # should have_many suppliers). If a :uid is supplied, checks 
  # suppliers belonging to organisation with uid and if not for suppliers with matching name
  def self.find_from_params(params)
    if params[:uid].blank?
      params[:name].blank? ? nil : params[:organisation].suppliers.find_by_name(params[:name])
    else
      params[:organisation].suppliers.find_by_uid(params[:uid])
    end 
  end

  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising supplier titles
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_company_title(raw_title)
  end
  
  # returns associated suppliers (i.e. those with same company)
  def associateds
    return [] unless payee
    payee.supplying_relationships - [self]
  end
  
  # convenience method for assigning company given company number. Creates company if no company with given company_number exists
  def company_number=(comp_no)
    if payee
      payee.update_attribute(:company_number, comp_no)
    else
      company = Company.match_or_create(:company_number => comp_no)
      update_attribute(:payee, company)
    end
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/suppliers/#{to_param}"
  end
  
  # strip excess spaces and UTF8 spaces from name
  def name=(raw_name)
    self[:name] = NameParser.strip_all_spaces(raw_name) if raw_name
  end

  # alias populate_basic_info as perform so that this gets run when doing delayed_job on a company
  def perform
    if payee = possible_payee
      update_attribute(:payee, payee)
    else
      update_attribute(:failed_payee_search, true)
    end
  end

  def possible_payee
    return Company.from_title(name) if Company.probable_company?(name)
    case name
    when /Police Authority/i
      PoliceAuthority.find_by_name(name)
    when /Council|(London Borough)|(City of)|(London Authority)/i
      Council.find_by_normalised_title(Council.normalise_title(name))
    else
      Charity.find_by_title(name)||Quango.find_by_title(name)
    end
  end
  
  def to_param
    "#{id}-#{title.parameterize}"
  end
  
  def update_supplier_details(details)
    non_nil_attribs = details.attributes.delete_if { |k,v| v.blank? }
    company = Company.match_or_create(non_nil_attribs.except(:source_for_info))
    unless company.new_record? # it hasn't successfully saved
      self.payee = company
      self.save
    end
  end
  
  # convenience method for assigning company given vat number. Creates company if no company with given vat_number exists
  def vat_number=(vat_number)
    if payee
      payee.update_attribute(:vat_number, vat_number)
    else
      company = Company.match_or_create(:vat_number => vat_number)
      update_attribute(:payee, company)
    end
  end
  
  private
  def queue_for_matching_with_payee
    Delayed::Job.enqueue(self)
  end
end

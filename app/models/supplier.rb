class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  has_many :financial_transactions, :order => 'date', :dependent => :destroy
  include SpendingStatUtilities::Base
  # has_one :spending_stat, :as => :organisation, :dependent => :destroy
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  named_scope :unmatched, :conditions => {:payee_id => nil}
  named_scope :filter_by, lambda { |filter_hash| filter_hash[:name] ? 
                                  { :conditions => ["name LIKE ?", "%#{filter_hash[:name]}%"] } : 
                                  {} }
  # before_save :update_spending_stat
  after_create :match_with_existing_company
  alias_attribute :title, :name
  # delegate :total_spend, :average_monthly_spend, :average_transaction_value, :to => :spending_stat, :allow_nil => true
  
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
    company = Company.match_or_create_from_company_number(comp_no)
    update_attribute(:payee, company)
  end
  
  def find_and_associate_new_company
    possible_companies = CompanyUtilities::Client.new.find_company_from_name(title) || 
                           (title.match(/&/) ? CompanyUtilities::Client.new.find_company_from_name(title.gsub(/\s?&\s?/, ' and ')) : nil)
    if possible_companies && (matched_company = possible_companies.size == 1 ? possible_companies.first : 
                                                     possible_companies.detect{ |pc| Company.normalise_title(pc[:title]) == Company.normalise_title(title) })
    else
      update_attribute(:failed_payee_search, true)
      return
    end
    self.payee = Company.create!(matched_company)
    self.save!
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/suppliers/#{to_param}"
  end

  def possible_payee
    case name
    when /Ltd|Limited|PLC/i
      Company.matches_title(name)
    when /Police Authority/i
      PoliceAuthority.find_by_name(name)
    when /Council|(London Borough)|(City of)/i
      Council.find_by_normalised_title(Council.normalise_title(name))
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
  
  private
  def match_with_existing_company
    if payee = possible_payee
      update_attribute(:payee, payee)
    end
  end
end

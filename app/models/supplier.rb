class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  has_many :financial_transactions, :order => 'date'
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  before_save :update_spending_info
  after_create :match_with_existing_company
  alias_attribute :title, :name
  
  def validate
    errors.add_to_base('Either a name or uid is required') if name.blank? && uid.blank?
  end

  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising supplier titles
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_company_title(raw_title)
  end
  
  def calculated_total_spend
    financial_transactions.sum(:value)
  end
  
  def calculated_average_monthly_spend
    return if financial_transactions.blank?
    oldest, newest = self.financial_transactions.values_at(0,-1) #nb we already get in date order
    months_covered = (newest.date.year - oldest.date.year) * 12 + (newest.date.month - oldest.date.month) + 1 # add one because we want the number of months covered, not just the difference
    financial_transactions.sum(:value)/(months_covered)
  end
  
  # returns associated suppliers (i.e. those with same company)
  def associateds
    return [] unless payee
    payee.supplying_relationships - [self]
  end
    
  # convenience method for assigning company given company number. Creates company if no company with given company_number exists
  def company_number=(comp_no)
    company = Company.find_or_create_by_company_number(comp_no)
    update_attribute(:payee, company)
  end
  
  def possible_payee
    case name
    when /Ltd|Limited|PLC/i
      Company.matches_title(name)
    when /Police Authority/i
      PoliceAuthority.find_by_name(name)
    when /Council|(London Borough)|(City of)/
      Council.find_by_normalised_title(Council.normalise_title(name))
    end
  end
  
  def to_param
    "#{id}-#{title.parameterize}"
  end
  
  def update_supplier_details(details)
    non_nil_attribs = details.attributes.delete_if { |k,v| v.blank? }
    update_attributes(non_nil_attribs)
  end
  
  private
  def update_spending_info
    self.total_spend = calculated_total_spend
    self.average_monthly_spend = calculated_average_monthly_spend
  end
  
  def match_with_existing_company
    if payee = possible_payee
      update_attribute(:payee, payee)
    end
  end
end

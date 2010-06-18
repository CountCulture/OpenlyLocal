class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  belongs_to :company
  has_many :financial_transactions, :order => 'date'
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  before_save :update_total_spend
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
  
  # returns associated suppliers (i.e. those with same company)
  def associateds
    return [] unless company
    company.suppliers - [self]
  end
  
  # overwrites normal accessor to return nil if company_number attribute is blank or '-1' (which is used to denote failed search)
  def company_number
    (self[:company_number].blank? || self[:company_number] == '-1') ? nil : self[:company_number]
  end
  
  private
  def update_total_spend
    self.total_spend = calculated_total_spend
  end
  
  def match_with_existing_company
    if company = Company.matches_title(name)
      update_attribute(:company, company)
    end
  end
end

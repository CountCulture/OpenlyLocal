class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  has_many :financial_transactions
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  alias_attribute :title, :name
  
  def validate
    errors.add_to_base('Either a name or uid is required') if name.blank? && uid.blank?
  end

  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising supplier titles
  def self.normalise_title(raw_title)
    semi_normed_title = raw_title.gsub(/\bT\/A\b.+/i, '').gsub(/\./,'').sub(/ltd/i, 'limited').sub(/public limited company/i, 'plc')
    TitleNormaliser.normalise_title(semi_normed_title).downcase
  end
  
  # overwrites normal accessor to return nil if company_number attribute is blank or '-1' (which is used to denote failed search)
  def company_number
    (self[:company_number].blank? || self[:company_number] == '-1') ? nil : self[:company_number]
  end
  
  # returns companies_house url via companies open house redirect
  def companies_house_url
    "http://companiesopen.org/uk/#{company_number}/companies_house" unless company_number.blank?
  end
  
end

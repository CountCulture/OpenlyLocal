class Charity < ActiveRecord::Base
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  include SpendingStatUtilities::Base
  include AddressMethods
  
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
end

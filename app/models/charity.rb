class Charity < ActiveRecord::Base
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  include SpendingStatUtilities::Base
  include AddressMethods
  include ResourceMethods
  
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
  
  def charity_commission_url
    "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{charity_number}&SubsidiaryNumber=0"
  end  
end

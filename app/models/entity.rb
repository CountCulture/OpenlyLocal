class Entity < ActiveRecord::Base
  PossibleTypes = { 'NDPB' => ['Non-Departmental Body'],
                    'ALB' => ['Arms Length Body'],
                    'Public Corporation' => ['Public Corporation'],
                    'Association' => ['Association'],
                    'RIEP' => ['Regional Improvement & Efficiency Partnership'],
                    'Dept' => ['Government Department or Ministry']}
  
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  include SpendingStatUtilities::Payer
  include TitleNormaliser::Base
  include AddressUtilities::Base
  include ResourceMethods
  default_scope :order => 'title'

  validates_presence_of :title
  serialize :other_attributes
  alias_attribute :url, :website
  
  def openlylocal_url
    "http://#{DefaultDomain}/entities/#{to_param}"
  end
  
  def resource_uri
    "http://#{DefaultDomain}/id/entities/#{id}"
  end
                 
end

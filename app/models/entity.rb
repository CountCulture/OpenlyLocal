class Entity < ActiveRecord::Base
  PossibleTypes = { 'NDPB' => ['Non-Departmental Body'],
                    'ALB' => ['Arms Length Body'],
                    'Public Corporation' => ['Public Corporation'],
                    'Association' => ['Association'],
                    'RIEP' => ['Regional Improvement & Efficiency Partnership'],
                    'Dept' => ['Government Department or Ministry']}
  
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  has_many :suppliers, :as => :organisation
  has_many :financial_transactions, :through => :suppliers
  default_scope :order => 'title'
  include SpendingStatUtilities::Base
  include AddressMethods
  include ResourceMethods
  validates_presence_of :title
  before_save :normalise_title
  serialize :other_attributes
  
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_title(raw_title)
  end
  
  def resource_uri
    "http://#{DefaultDomain}/id/entities/#{id}"
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
               
end

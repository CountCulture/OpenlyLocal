class Entity < ActiveRecord::Base
  PossibleTypes = { 'NDPB' => ['Non-Departmental Body'],
                    'ALB' => ['Arms Length Body'],
                    'Public Corporation' => ['Public Corporation'],
                    'Association' => ['Association'],
                    'RIEP' => ['Regional Improvement & Efficiency Partnership']}
  
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  has_many :suppliers, :as => :organisation
  has_many :financial_transactions, :through => :suppliers
  default_scope :order => 'title'
  include SpendingStatUtilities::Base
  include AddressMethods
  validates_presence_of :title
  before_save :normalise_title
  
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_title(raw_title)
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
               
end

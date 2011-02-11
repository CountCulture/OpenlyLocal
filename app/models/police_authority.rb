class PoliceAuthority < ActiveRecord::Base
  include ResourceMethods
  belongs_to :police_force
  has_many :councils, :through => :police_force
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  
  validates_presence_of :name, :police_force_id
  validates_uniqueness_of :name, :police_force_id
  default_scope :order => "name"
  alias_attribute :title, :name
  
  def resource_uri
    "http://#{DefaultDomain}/id/police_authorities/#{id}"
  end
  
end

class PoliceForce < ActiveRecord::Base
  include ResourceMethods
  include TwitterAccountMethods
  has_many :councils
  has_many :police_teams
  has_many :crime_areas
  has_many :suppliers, :as => :organisation
  has_many :financial_transactions, :through => :suppliers
  has_one :police_authority
  has_one :force_crime_area, :class_name => "CrimeArea", :foreign_key => "police_force_id", :conditions => {:level => 1}
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  validates_uniqueness_of :url
  default_scope :order => 'name'
  alias_attribute :title, :name
  
end

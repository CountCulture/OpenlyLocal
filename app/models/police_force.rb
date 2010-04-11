class PoliceForce < ActiveRecord::Base
  include ResourceMethods
  include TwitterAccountMethods
  has_many :councils
  has_many :police_teams
  has_many :crime_areas
  has_one :police_authority
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  validates_uniqueness_of :url
  default_scope :order => 'name'
  alias_attribute :title, :name
  
end

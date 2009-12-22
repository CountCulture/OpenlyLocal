class PoliceAuthority < ActiveRecord::Base
  include ResourceMethods
  belongs_to :police_force
  has_many :councils, :through => :police_force
  validates_presence_of :name, :police_force_id
  validates_uniqueness_of :name, :police_force_id
  default_scope :order => "name"
  alias_attribute :title, :name
  
end

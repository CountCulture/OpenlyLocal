class PoliceForce < ActiveRecord::Base
  include ResourceMethods
  has_many :councils
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  validates_uniqueness_of :url
  default_scope :order => "name"
  alias_attribute :title, :name
  
end

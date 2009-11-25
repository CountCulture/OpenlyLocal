class PoliceForce < ActiveRecord::Base
  has_many :councils
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  validates_uniqueness_of :url
end

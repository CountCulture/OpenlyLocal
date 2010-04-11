class CrimeArea < ActiveRecord::Base
  belongs_to :police_force
  validates_presence_of :uid, :name, :level, :police_force_id
  validates_uniqueness_of :uid, :scope => :police_force_id
  serialize :crime_rates
  serialize :total_crimes
end

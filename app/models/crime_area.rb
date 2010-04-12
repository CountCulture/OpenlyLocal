class CrimeArea < ActiveRecord::Base
  belongs_to :police_force
  validates_presence_of :uid, :name, :level, :police_force_id
  validates_uniqueness_of :uid, :scope => :police_force_id
  serialize :crime_rates
  serialize :total_crimes
  
  # tweaks crime_rates to compare with force rates (if they exist)
  def crime_rate_comparison
    return if crime_rates.blank?
    if force_crime_rates = police_force.force_crime_area.try(:crime_rates)
      crime_rates.collect do |period|
        matching_force_period = force_crime_rates.detect{ |p| p['date']==period['date'] }
        matching_force_period ? period.merge('force_value' => matching_force_period['value']) : period
      end
    else
      crime_rates
    end
  end
end

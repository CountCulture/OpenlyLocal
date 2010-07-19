class SpendingStat < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id
  
  def calculated_average_monthly_spend
    return if organisation.financial_transactions.blank?
    oldest, newest = organisation.financial_transactions.values_at(0,-1) #nb we already get in date order
    months_covered = (newest.date.year - oldest.date.year) * 12 + (newest.date.month - oldest.date.month) + 1 # add one because we want the number of months covered, not just the difference
    organisation.financial_transactions.sum(:value)/(months_covered)
  end
  
  def calculated_total_spend
    organisation.financial_transactions.sum(:value)
  end
  
  def perform
    update_attributes(:total_spend => calculated_total_spend, :average_monthly_spend => calculated_average_monthly_spend)
  end
end

class SpendingStat < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id
  serialize :spend_by_month
  
  def calculated_average_monthly_spend
    return if organisation.financial_transactions.blank?
    organisation.financial_transactions.sum(:value)/months_covered
  end
  
  def calculated_total_spend
    organisation.financial_transactions.sum(:value)
  end
  
  def perform
    update_attributes(:total_spend => calculated_total_spend, :average_monthly_spend => calculated_average_monthly_spend)
  end
  
  def earliest_transaction_date
    first_transaction = organisation.financial_transactions.first(:order => 'date')
    first_transaction.date - first_transaction.date_fuzziness.to_i.days
  end
  
  def latest_transaction_date
    last_transaction = organisation.financial_transactions.first(:order => 'date DESC')
    last_transaction.date + last_transaction.date_fuzziness.to_i.days
  end
  
  def months_covered
    (latest_transaction_date.year - earliest_transaction_date.year) * 12 + (latest_transaction_date.month - earliest_transaction_date.month) + 1 # add one because we want the number of months covered, not just the difference
  end
end

class SpendingStat < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id
  serialize :spend_by_month
  
  def calculated_average_monthly_spend
    return if organisation.financial_transactions.blank?
    organisation.financial_transactions.sum(:value)/months_covered
  end
  
  # Returns array of arrays, corresponding to spend per month. The array is 
  def calculated_spend_by_month
    return if organisation.financial_transactions.count == 0
    res_hsh = {}
    # normal_fts = organisation.financial_transactions.all(:conditions => 'date_fuzziness IS NULL')
    normal_fts = organisation.financial_transactions.sum(:value, :group=>'last_day(date)', :conditions => 'date_fuzziness IS NULL', :order => 'date')
    
    fuzzy_fts = organisation.financial_transactions.all(:conditions => 'date_fuzziness IS NOT NULL')
    normal_fts.each{ |ft| res_hsh[ft.first.to_date.beginning_of_month] = res_hsh[ft.first.to_date.beginning_of_month].to_f + ft.last}
    fuzzy_fts.each do |fft|
      fft.averaged_date_and_value.each do |avg_dv|
        res_hsh[avg_dv.first.beginning_of_month] = res_hsh[avg_dv.first.beginning_of_month].to_f + avg_dv.last
      end
    end
    
    months_with_vals = res_hsh.sort
    
    first_month, last_month = months_with_vals.first, months_with_vals.last
    all_months = [months_with_vals.shift]
    month_date = first_month.first
    difference_in_months_between_dates(first_month.first, last_month.first).times do |i|
      month_date = (month_date + 32.days).beginning_of_month
      matched_month_value = (months_with_vals.first.first == month_date ? months_with_vals.shift.last : nil)
      all_months << [month_date, matched_month_value]
    end
    all_months
  end
  
  def calculated_total_spend
    organisation.financial_transactions.sum(:value)
  end
  
  def perform
    update_attributes(:total_spend => calculated_total_spend, 
                      :average_monthly_spend => calculated_average_monthly_spend,
                      :spend_by_month => calculated_spend_by_month)
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
    difference_in_months_between_dates(earliest_transaction_date, latest_transaction_date) + 1 # add one because we want the number of months covered, not just the difference
  end
  
  private
  def difference_in_months_between_dates(early_date,later_date)
    (later_date.year - early_date.year) * 12 + (later_date.month - early_date.month)
  end
  
end

class SpendingStat < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id
  serialize :spend_by_month
  serialize :breakdown
  
  # Overrides ActiveRecord method to return true if main stat values are blank
  def blank?
    %w(total_spend average_monthly_spend average_transaction_value).all?{ |a| self.send(a).blank? || (self.send(a) == 0) }
  end
  
  def calculated_average_monthly_spend
    return if calculated_total_spend.blank? || calculated_total_spend == 0
    calculated_total_spend/calculated_months_covered
  end
  
  def calculated_payee_breakdown
    return if !organisation.respond_to?(:financial_transactions) || organisation.is_a?(Supplier)
    res = organisation.financial_transactions.sum(:value, :group => "suppliers.payee_type").to_hash
    res.blank? ? nil : res
  end
  
  # Returns array of arrays, corresponding to spend per month. The array is 
  def calculated_spend_by_month
    return if organisation.financial_transactions.count == 0
    res_hsh = {}
    ft_sums = organisation.financial_transactions.sum(:value, :group => 'last_day(date)', :conditions => 'date_fuzziness IS NULL', :order => 'date').to_a
    fuzzy_sums = organisation.financial_transactions.all(:conditions => 'date_fuzziness IS NOT NULL', :select=>'sum(VALUE) AS value, DATE AS date, date_fuzziness', :group=>'date, date_fuzziness')

    fuzzy_sums.each{ |fs| ft_sums += fs.averaged_date_and_value }

    ft_sums.each do |ft_sum|
      res_hsh[ft_sum.first.to_date.beginning_of_month] = res_hsh[ft_sum.first.to_date.beginning_of_month].to_f + ft_sum.last
    end

    months_with_vals = res_hsh.sort
    
    first_month, last_month = months_with_vals.first, months_with_vals.last
    all_months = [months_with_vals.shift]
    month_date = first_month.first
    self.class.difference_in_months_between_dates(first_month.first, last_month.first).times do |i|
      month_date = (month_date + 32.days).beginning_of_month
      matched_month_value = (months_with_vals.first.first == month_date ? months_with_vals.shift.last : nil)
      all_months << [month_date, matched_month_value]
    end
    all_months
  end
  
  def calculated_total_spend
    @calculated_total_spend ||= organisation.financial_transactions.sum(:value)
  end
  
  def calculated_earliest_transaction_date
    return @calculated_earliest_transaction_date if @calculated_earliest_transaction_date
    extra_params = organisation.is_a?(Supplier) ? {} : {:from => 'financial_transactions FORCE INDEX(index_financial_transactions_on_date)'}
    return unless first_transaction = organisation.financial_transactions.earliest.first(extra_params)
    @calculated_earliest_transaction_date = first_transaction.date - first_transaction.date_fuzziness.to_i.days
  end
  
  def calculated_latest_transaction_date
    return @calculated_latest_transaction_date if @calculated_latest_transaction_date
    extra_params = {:from => 'financial_transactions FORCE INDEX(index_financial_transactions_on_date)'}
    return unless last_transaction = organisation.financial_transactions.latest.first(extra_params)
    # return unless last_transaction = organisation.financial_transactions.latest.first(:from => 'financial_transactions FORCE INDEX(index_financial_transactions_on_date)', :order => 'date DESC')
    @calculated_latest_transaction_date = last_transaction.date + last_transaction.date_fuzziness.to_i.days
  end
  
  def calculated_months_covered
    self.class.difference_in_months_between_dates(calculated_earliest_transaction_date, calculated_latest_transaction_date) + 1 # add one because we want the number of months covered, not just the difference
  end
  
  def months_covered
    self.class.difference_in_months_between_dates(earliest_transaction, latest_transaction) + 1 # add one because we want the number of months covered, not just the difference
  end
  
  def perform
    update_attributes(:total_spend => calculated_total_spend, 
                      :average_monthly_spend => calculated_average_monthly_spend,
                      :spend_by_month => calculated_spend_by_month,
                      :breakdown => calculated_payee_breakdown,
                      :earliest_transaction => calculated_earliest_transaction_date,
                      :latest_transaction => calculated_latest_transaction_date
                      )
  end
  
  private
  def self.difference_in_months_between_dates(early_date,later_date)
    (later_date.year - early_date.year) * 12 + (later_date.month - early_date.month)
  end
    
end

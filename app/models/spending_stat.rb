# The SpendingStat class is a repository for data about an associated object's (an organisation) spending 
# and/or the payements it has received. Because of how this has develoed some of the attributes' naming is 
# not as clear as it should be
# The following attributes relate to spending (i.e. payments *to* another party):
# # total_spend
# # average_monthly_spend
# # average_transaction_value
# # spend_by_month
# # earliest_transaction
# # latest_transaction
# # transaction_count
# # breakdown

# These attributes related to payments received *from* another party. This obviously includes payments to companies
# but in the case of councils or entities such as government departments they received payments as well as making them
# # total_received
# # total_received_from_councils
# # payer_breakdown

class SpendingStat < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id
  serialize :spend_by_month
  serialize :breakdown
  serialize :payer_breakdown
  
  # Overrides ActiveRecord method to return true if main stat values are blank
  def blank?
    %w(total_spend average_monthly_spend average_transaction_value breakdown total_received total_received_from_councils).all?{ |a| self.send(a).blank? || (self.send(a) == 0) }
  end
  
  # convenience method to return the biggest council among payers. Looks in payer_breakdown, or returns nil.
  def biggest_council
    return if payer_breakdown.blank? || payer_breakdown.all?{ |o| o[:organisation_type] != 'Council' }
    council_details = payer_breakdown.select{ |o| o[:organisation_type] == 'Council'}.sort{|a,b| b[:total_spend] <=> a[:total_spend]}.first
    Council.find_by_id(council_details[:organisation_id])
  end
  
  def calculated_average_monthly_spend
    return if calculated_total_spend.blank? || calculated_months_covered.blank? || calculated_total_spend == 0
    calculated_total_spend/calculated_months_covered
  end
  
  def calculated_payee_breakdown
    return if !organisation.respond_to?(:payments) || organisation.is_a?(Supplier)
    res = organisation.payments.sum(:value, :group => "suppliers.payee_type").to_hash
    res.blank? ? nil : res
  end
  
  # Returns array of arrays, corresponding to spend per month. The array is 
  def calculated_spend_by_month
    return if !organisation.respond_to?(:payments) || organisation.payments.count == 0
    res_hsh = {}
    ft_sums = organisation.payments.sum(:value, :group => 'last_day(date)', :conditions => 'date_fuzziness IS NULL', :order => 'date').to_a
    fuzzy_sums = organisation.payments.all(:conditions => 'date_fuzziness IS NOT NULL', :select=>'sum(VALUE) AS value, DATE AS date, date_fuzziness', :group=>'date, date_fuzziness')

    fuzzy_sums.each{ |fs| ft_sums += fs.averaged_date_and_value }

    ft_sums.each do |ft_sum|
      res_hsh[ft_sum.first.to_date.beginning_of_month] = res_hsh[ft_sum.first.to_date.beginning_of_month].to_f + ft_sum.last
    end

    months_with_vals = res_hsh.sort
    
    first_month, last_month = months_with_vals.first, months_with_vals.last
    spend_by_month_array(first_month.first, last_month.first, months_with_vals)
  end
  
  def calculated_total_spend
    @calculated_total_spend ||= 
      if organisation.respond_to?(:payments)
        organisation.payments.sum(:value) 
      elsif organisation.respond_to?(:financial_transactions) #then it's a supplier
        organisation.payments.sum(:value) 
      end
  end
  
  def calculated_total_received
    @calculated_total_received ||= organisation.payments_received.sum(:value)
  end
  
  def calculated_total_received_from_councils
    return @calculated_total_received_from_councils if @calculated_total_received_from_councils
    @calculated_total_received_from_councils ||= calculated_payer_breakdown&&calculated_payer_breakdown.select{ |o| o[:organisation_type] == 'Council' }.sum{|o| o[:total_spend]}
  end
  
  def calculated_transaction_count
    @calculated_total_received ||= organisation.payments.count if organisation.respond_to?(:payments)
  end
  
  def calculated_earliest_transaction_date
    return unless organisation.respond_to?(:payments)
    return @calculated_earliest_transaction_date if @calculated_earliest_transaction_date
    # extra_params = organisation.is_a?(Supplier) ? {} : {:from => 'financial_transactions FORCE INDEX(index_financial_transactions_on_date)'}
    extra_params={}
    return unless first_transaction = organisation.payments.earliest.first(extra_params)
    @calculated_earliest_transaction_date = first_transaction.date - first_transaction.date_fuzziness.to_i.days
  end
  
  def calculated_latest_transaction_date
    return unless organisation.respond_to?(:payments)
    return @calculated_latest_transaction_date if @calculated_latest_transaction_date
    # extra_params = organisation.is_a?(Supplier) ? {} : {:from => 'financial_transactions FORCE INDEX(index_financial_transactions_on_date)'}
    extra_params={}
    return unless last_transaction = organisation.payments.latest.first(extra_params)
    @calculated_latest_transaction_date = last_transaction.date + last_transaction.date_fuzziness.to_i.days
  end
  
  def calculated_months_covered
    return unless calculated_earliest_transaction_date&&calculated_latest_transaction_date
    self.class.difference_in_months_between_dates(calculated_earliest_transaction_date, calculated_latest_transaction_date) + 1 # add one because we want the number of months covered, not just the difference
  end
  
  def calculated_average_transaction_value
    return @calculated_average_transaction_value if @calculated_average_transaction_value
    @calculated_average_transaction_value = calculated_total_spend/calculated_transaction_count if calculated_total_spend && (calculated_transaction_count.to_i > 0)
  end
  
  def calculated_payer_breakdown
    return @bdown if @bdown
    return unless suppliers = organisation.respond_to?(:supplying_relationships)&&organisation.supplying_relationships(:include => :spending_stat)
    @bdown = suppliers.group_by(&:organisation).collect do |supplier_org, sups|
      res = {}
      res[:total_spend] = sups.sum{ |s| (s.spending_stat&&s.spending_stat.total_spend).to_f }
      res[:transaction_count] = sups.sum{ |s| (s.spending_stat&&s.spending_stat.transaction_count).to_i}
      res[:organisation_id] = supplier_org.id
      res[:organisation_type] = supplier_org.class.to_s
      res[:average_transaction_size] = res[:total_spend]/res[:transaction_count] rescue nil
      res
    end
  end
  
  def months_covered
    return unless earliest_transaction && latest_transaction
    self.class.difference_in_months_between_dates(earliest_transaction, latest_transaction) + 1 # add one because we want the number of months covered, not just the difference
  end
  
  # convenience method to return number of councils in payer breakdown
  def number_of_councils
    payer_breakdown && payer_breakdown.select{ |p| p[:organisation_type] == 'Council' }.size
  end
  
  def perform
    # breakdown = (organisation.is_a?(Company) || organisation.is_a?(Charity)) ? calculated_payer_breakdown : calculated_payee_breakdown
    update_attributes(:total_spend => calculated_total_spend, 
                      :average_monthly_spend => calculated_average_monthly_spend,
                      :spend_by_month => calculated_spend_by_month,
                      :breakdown => calculated_payee_breakdown,
                      :payer_breakdown => calculated_payer_breakdown,
                      :earliest_transaction => calculated_earliest_transaction_date,
                      :latest_transaction => calculated_latest_transaction_date,
                      :total_received_from_councils => calculated_total_received_from_councils,
                      :transaction_count => calculated_transaction_count,
                      :average_transaction_value => calculated_average_transaction_value
                      )
  end
  
  def update_from(fin_trans)
    payer_or_supplier = (fin_trans.supplier.organisation == organisation) || (fin_trans.supplier == organisation)
    if payer_or_supplier
      self.earliest_transaction = fin_trans.date if earliest_transaction.nil? || (fin_trans.date < earliest_transaction)
      self.latest_transaction = fin_trans.date if latest_transaction.nil? || (fin_trans.date > latest_transaction)
      self.transaction_count = transaction_count.to_i + 1
      self.total_spend = total_spend.to_f + fin_trans.value
      self.average_transaction_value = total_spend/transaction_count
      self.average_monthly_spend = total_spend/months_covered
      existing_spend_by_month = spend_by_month ? spend_by_month.dup : []
      if !existing_spend_by_month.blank? && (matched = existing_spend_by_month.assoc(fin_trans.date.beginning_of_month))
        existing_spend_by_month[existing_spend_by_month.index(matched)] = [matched.first, matched.last.to_f + fin_trans.value]
      else
        existing_spend_by_month << [fin_trans.date.beginning_of_month, fin_trans.value]
      end
      self.spend_by_month = spend_by_month_array(earliest_transaction.beginning_of_month, latest_transaction.beginning_of_month, existing_spend_by_month.sort{ |a,b| a.first <=> b.first })
      self.breakdown = update_breakdown_with_transaction(self.breakdown, fin_trans)
    else
      self.total_received = total_received.to_i + fin_trans.value
      self.total_received_from_councils = total_received_from_councils.to_i + fin_trans.value if fin_trans.supplier.organisation_type == 'Council'
      self.payer_breakdown = update_payer_breakdown_with_transaction(payer_breakdown, fin_trans)
    end
    save!
  end
  
  private
  def self.difference_in_months_between_dates(early_date,later_date)
    return unless early_date&&later_date
    (later_date.year - early_date.year) * 12 + (later_date.month - early_date.month)
  end
  
  def spend_by_month_array(first_date, last_date, vals)
    months_with_vals = vals.dup
    
    res = [months_with_vals.shift]
    month_date = first_date
    self.class.difference_in_months_between_dates(first_date, last_date).times do
      month_date = (month_date + 32.days).beginning_of_month #increment month to beginning of next month
      matched_month_value = (months_with_vals.first.first == month_date ? months_with_vals.shift.last : nil)
      res << [month_date, matched_month_value]
    end
    res
  end
  
  def update_breakdown_with_transaction(exist_breakdown, fin_trans)
    return nil if organisation.is_a?(Supplier)
    payee = fin_trans.payee && fin_trans.payee.class.to_s # nil if payee nil
    new_breakdown = exist_breakdown ? exist_breakdown.dup : {}
    new_breakdown[payee] = new_breakdown[payee].to_f + fin_trans.value
    new_breakdown
  end
    
  def update_payer_breakdown_with_transaction(exist_breakdown, fin_trans)
    new_breakdown = exist_breakdown ? exist_breakdown.dup : []
    existing_entry_for_org = new_breakdown.detect{ |e| (e[:organisation_id].to_s == fin_trans.supplier.organisation_id.to_s) && (e[:organisation_type] == fin_trans.supplier.organisation_type)} || {}
    new_breakdown.delete(existing_entry_for_org)
    transaction_count = existing_entry_for_org[:transaction_count].to_i + 1
    total_spend = existing_entry_for_org[:total_spend].to_f + fin_trans.value
    existing_entry_for_org = {:organisation_id => fin_trans.supplier.organisation_id, 
                              :organisation_type => fin_trans.supplier.organisation_type,
                              :transaction_count => transaction_count,
                              :average_transaction_value => total_spend/transaction_count,
                              :total_spend => total_spend
                              }
    new_breakdown << existing_entry_for_org
    new_breakdown
  end
    
end

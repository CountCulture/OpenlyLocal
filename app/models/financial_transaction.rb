class FinancialTransaction < ActiveRecord::Base
  belongs_to :supplier
  validates_presence_of :supplier_id, :value, :date
  
  # strips out commas and pound signs
  def value=(raw_value)
    self[:value] = raw_value.is_a?(String) ? raw_value.gsub(/£|,/,'') : raw_value
  end
end

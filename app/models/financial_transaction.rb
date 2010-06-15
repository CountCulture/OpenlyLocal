class FinancialTransaction < ActiveRecord::Base
  belongs_to :supplier, :dependent => :destroy
  validates_presence_of :supplier_id, :value, :date
  
  # strips out commas and pound signs
  def value=(raw_value)
    self[:value] =
    if raw_value.is_a?(String)
      cleaned_up_value = raw_value.gsub(/£|,|\s/,'')
      cleaned_up_value.match(/^\(([\d\.]+)\)$/) ? "-#{$1}" : cleaned_up_value
    else
      raw_value
    end
  end
end

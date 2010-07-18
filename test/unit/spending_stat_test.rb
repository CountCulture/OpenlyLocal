require 'test_helper'

class SpendingStatTest < ActiveSupport::TestCase
  
  should belong_to :organisation
  should validate_presence_of :organisation_type
  should validate_presence_of :organisation_id
  
  should have_db_column :total_spend
  should have_db_column :average_monthly_spend
  should have_db_column :average_transaction_value
end

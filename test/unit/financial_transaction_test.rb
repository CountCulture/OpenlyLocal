require 'test_helper'

class FinancialTransactionTest < ActiveSupport::TestCase
  subject { @financial_transaction }
  
  context "The FinancialTransaction class" do
    setup do
      @financial_transaction = Factory(:financial_transaction)
    end
    
    should_validate_presence_of :supplier_id, :value, :date
    should belong_to :supplier
    
    should_have_db_columns :value, 
                           :uid, 
                           :description, 
                           :date, 
                           :department_name, 
                           :source_url, 
                           :cost_centre, 
                           :service, 
                           :transaction_type, 
                           :source_url,
                           :date_fuzziness
    context "when setting value" do
      setup do
        
      end

      should "assign value as expected" do
        assert_equal 34567.23, Factory(:financial_transaction, :value => 34567.23).value
      end
      
      should "strip out commas" do
        assert_equal 34567.23, Factory(:financial_transaction, :value => '34,567.23').value
      end
      
      should "strip out spaces" do
        assert_equal 34567.23, Factory(:financial_transaction, :value => '34, 567.23 ').value
      end
      
      should "treat brackets as negative numbers" do
        assert_equal -34567.23, Factory(:financial_transaction, :value => '(34,567.23)').value
      end
      
      should "strip out pound signs" do
        assert_equal 3467.23, Factory(:financial_transaction, :value => '£3467.23').value
      end
    end
    
  end
end

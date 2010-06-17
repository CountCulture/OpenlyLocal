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
                           :date_fuzziness
                           
    context "when setting value" do

      should "assign value as expected" do
        assert_equal 34567.23, Factory(:financial_transaction, :value => 34567.23).value
        assert_equal -34567.23, Factory(:financial_transaction, :value => -34567.23).value
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
    
    context 'when setting department' do
      should 'squish spaces' do
        assert_equal 'Foo Department', Factory.build(:financial_transaction, :department_name => ' Foo   Department   ').department_name
      end
      
      should 'replace mispellings' do
        assert_equal 'Children\'s Department', Factory.build(:financial_transaction, :department_name => 'Childrens\' Department ').department_name
        assert_equal 'Children\'s Department', Factory.build(:financial_transaction, :department_name => 'Childrens Department ').department_name
      end
    end
    
    context "when saving" do
      setup do
        @supplier = @financial_transaction.supplier
        @another_financial_transaction = Factory(:financial_transaction, :description => 'foobar***', :supplier => @supplier, :value => 42)
      end

      should "update total_spend of associated supplier" do
        @financial_transaction.value = 31
        @financial_transaction.save!
        assert_equal 73, @supplier.reload.total_spend
      end
    end
  end
end

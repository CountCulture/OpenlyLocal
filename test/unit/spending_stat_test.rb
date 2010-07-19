require 'test_helper'

class SpendingStatTest < ActiveSupport::TestCase
  def setup
    @spending_stat = Factory(:spending_stat)
    @supplier = @spending_stat.organisation
    @another_supplier = Factory(:supplier)
    @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 123.45, :date => 11.months.ago)
    @financial_transaction_2 = Factory(:financial_transaction, :supplier => @supplier, :value => -32.1, :date => 3.months.ago)
    @financial_transaction_3 = Factory(:financial_transaction, :supplier => @supplier, :value => 22.1, :date => 5.months.ago)
    @unrelated_financial_transaction = Factory(:financial_transaction, :supplier => @another_supplier, :value => 24.5)
  end
  
  context "The SpendingStat class" do

    should belong_to :organisation
    should validate_presence_of :organisation_type
    should validate_presence_of :organisation_id

    should have_db_column :total_spend
    should have_db_column :average_monthly_spend
    should have_db_column :average_transaction_value

  end
  
  context "An instance of the SpendingStat class" do

    context "when performing" do

      should "should calculate total_spend" do
        @spending_stat.expects(:calculated_total_spend)
        @spending_stat.perform
      end
      
      should "should update with calculated_total_spend" do
        @spending_stat.stubs(:calculated_total_spend).returns(432.1)
        @spending_stat.perform
        assert_equal 432.1, @spending_stat.reload.total_spend
      end

      should "should recalculate average_monthly_spend" do
        @spending_stat.expects(:calculated_average_monthly_spend)
        @spending_stat.perform
      end
      
      should "should update with average_monthly_spend" do
        @spending_stat.stubs(:calculated_average_monthly_spend).returns(432.1)
        @spending_stat.perform
        assert_equal 432.1, @spending_stat.reload.average_monthly_spend
      end
    end

    context "when calculating total_spend" do
      should "sum all financial transactions for organisation" do
        assert_in_delta (123.45 - 32.1 + 22.1), @spending_stat.calculated_total_spend, 2 ** -10
      end
    end
    context "when calculating average_monthly_spend" do

      should "divide calculated_total_of spend for organisation by number of months" do
        assert_in_delta (123.45 - 32.1 + 22.1)/(8+1), @spending_stat.reload.calculated_average_monthly_spend, 2 ** -10 
      end
      
      should "return nil when no transactions" do
        assert_nil Factory(:spending_stat).calculated_average_monthly_spend
      end
    end
    
    
  end
  
end

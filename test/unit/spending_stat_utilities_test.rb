require 'test_helper'

class SpendingStatUtilitiesTest < ActiveSupport::TestCase
  
  context 'A class that mixes in SpendingStatUtilities::Base' do
    setup do
      @test_model_with_spending_stat = TestModelWithSpendingStat.create!
      @spending_stat = @test_model_with_spending_stat.create_spending_stat
    end
    
    should 'have one spending_stat' do
      assert @test_model_with_spending_stat.respond_to?(:spending_stat)
    end
    
    should "delegate total_spend to spending_stat" do
      assert_equal @spending_stat.total_spend, @test_model_with_spending_stat.total_spend
    end
    
    should "return for total_spend if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.total_spend
    end
    
    should "delegate average_monthly_spend to spending_stat" do
      assert_equal @spending_stat.average_monthly_spend, @test_model_with_spending_stat.average_monthly_spend
    end
    
    should "return for average_monthly_spend if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.average_monthly_spend
    end
    
    should "delegate average_transaction_value to spending_stat" do
      assert_equal @spending_stat.average_transaction_value, @test_model_with_spending_stat.average_transaction_value
    end
    
    should "return for average_transaction_value if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.average_transaction_value
    end
    
    context 'on creation' do
     should "create associated spending stat" do
        assert_difference "SpendingStat.count", 1 do
          tm = TestModelWithSpendingStat.create
          assert tm.spending_stat
          assert !tm.spending_stat.new_record?
        end
      end
      
      should "queue created spending stat for updating" do
        Delayed::Job.expects(:enqueue).with(kind_of(SpendingStat))
        TestModelWithSpendingStat.create
      end
      
    end
  end

end
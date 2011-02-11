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
    
    should "return nil for total_spend if no spending_stat" do
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
    
    should "have update_spending_stat_with method" do
      assert TestModelWithSpendingStat.new.respond_to?(:update_spending_stat_with)
    end
    
    context "and when updating spending_stat with financial_transaction" do
      setup do
        @financial_transaction = Factory(:financial_transaction)
      end

      should "update associated spending_stat with financial transaction" do
        @spending_stat.expects(:update_from).with(@financial_transaction)
        @test_model_with_spending_stat.update_spending_stat_with(@financial_transaction)
      end
      
      should "create spending_stat if no existing spending_stat" do
        @test_model_with_spending_stat.spending_stat.destroy
        @test_model_with_spending_stat.reload
        assert_difference "SpendingStat.count", 1 do
          @test_model_with_spending_stat.update_spending_stat_with(@financial_transaction)
        end
        assert @test_model_with_spending_stat.spending_stat
      end
      
      should "update newly created spending_stat with financial_transaction" do
        SpendingStat.any_instance.expects(:update_from).with(@financial_transaction)
        @test_model_with_spending_stat.update_spending_stat_with(@financial_transaction)
      end
    end
    
  end

  context "A class that mixes in SpendingStatUtilities::Payer" do
    setup do
      @test_model_with_spending_stat_payer = TestModelWithSpendingStatPayer.create!
    end

    should 'have many suppliers' do
      assert @test_model_with_spending_stat_payer.respond_to?(:suppliers)
    end
    
    should "have many payments" do
      assert @test_model_with_spending_stat_payer.respond_to?(:payments)
    end

    should 'have many suppliers as organisation' do
      supplier = Factory(:supplier, :organisation => @test_model_with_spending_stat_payer)
      assert_equal [supplier], @test_model_with_spending_stat_payer.suppliers
     end
    
    should 'have many payments through supplying_relationships' do
      supplier = Factory(:supplier, :organisation => @test_model_with_spending_stat_payer)
      payment = Factory(:financial_transaction, :supplier => supplier)
      assert_equal [payment], @test_model_with_spending_stat_payer.payments
    end
  end
  
  context "A class that mixes in SpendingStatUtilities::Payee" do
    setup do
      @test_model_with_spending_stat_payee = TestModelWithSpendingStatPayee.create!
    end

    should 'have many supplying_relationships as payee' do
      supplying_relationship = Factory(:supplier, :payee => @test_model_with_spending_stat_payee)
      assert_equal [supplying_relationship], @test_model_with_spending_stat_payee.supplying_relationships
     end
    
    should 'have many payments_received through supplying_relationships' do
      supplying_relationship = Factory(:supplier, :payee => @test_model_with_spending_stat_payee)
      payment_received = Factory(:financial_transaction, :supplier => supplying_relationship)
      assert_equal [payment_received], @test_model_with_spending_stat_payee.payments_received
    end
    
  end
  
end
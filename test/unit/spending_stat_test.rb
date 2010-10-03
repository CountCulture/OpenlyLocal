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
    should have_db_column :spend_by_month
    should have_db_column :breakdown
    
    should 'serialize spend_by_month' do
      assert_equal ['foo', 'bar'], Factory(:spending_stat, :spend_by_month => ['foo', 'bar']).reload.spend_by_month 
    end
    
    should 'serialize breakdown' do
      assert_equal ['foo', 'bar'], Factory(:spending_stat, :breakdown => ['foo', 'bar']).reload.breakdown 
    end
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
      
      should "should calculate spend_by_month" do
        @spending_stat.expects(:calculated_spend_by_month)
        @spending_stat.perform
      end
      
      should "should update with spend_by_month" do
        dummy_spend_by_month = [3.days.ago.to_date, 32.1]
        @spending_stat.stubs(:calculated_spend_by_month).returns(dummy_spend_by_month)
        @spending_stat.perform
        assert_equal dummy_spend_by_month, @spending_stat.reload.spend_by_month
      end

      should "should calculate payee breakdown" do
        @spending_stat.expects(:calculated_payee_breakdown)
        @spending_stat.perform
      end
      
      should "should update with payee_breakdown" do
        dummy_payee_breakdown = {'Company' => 123}
        @spending_stat.stubs(:calculated_payee_breakdown).returns(dummy_payee_breakdown)
        @spending_stat.perform
        assert_equal dummy_payee_breakdown, @spending_stat.reload.breakdown
      end

    end
    
    context "when returning earliest_transaction_date" do
      should "return first date" do
        assert_equal 11.months.ago.to_date, @spending_stat.earliest_transaction_date
      end
      
      context "and date has fuzziness" do
        setup do
          @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 23.45, :date => 12.months.ago, :date_fuzziness => 45)
        end

        should "should return date less fuziness" do
          assert_equal (12.months.ago.to_date - 45.days), @spending_stat.earliest_transaction_date
        end
      end
    end

    context "when returning latest_transaction_date" do
      should "return first date" do
        assert_equal 3.months.ago.to_date, @spending_stat.latest_transaction_date
      end
      
      context "and date has fuzziness" do
        setup do
          @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 23.45, :date => 2.months.ago, :date_fuzziness => 45)
        end

        should "should return date less fuziness" do
          assert_equal (2.months.ago.to_date + 45.days), @spending_stat.latest_transaction_date
        end
      end
    end
    
    context "when returning months_covered" do
      should "return number of months between earliest_transaction_date and latest_transaction_date" do
        @spending_stat.expects(:earliest_transaction_date).at_least_once.returns(5.months.ago)
        @spending_stat.expects(:latest_transaction_date).at_least_once.returns(45.days.ago)
        assert_equal 5, @spending_stat.months_covered
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
    
    context "when calculating spend_by_month" do
      context "in general" do
        setup do
          @new_ft = Factory(:financial_transaction, :date => (@financial_transaction_1.date.beginning_of_month + 8.days), :supplier => @supplier, :value => 199)
          @calc_sp = @spending_stat.calculated_spend_by_month
        end
        
        should 'return nil if no transactions' do
          assert_nil Factory(:supplier).spending_stat.calculated_spend_by_month
        end

        should "return array of arrays" do
          assert_kind_of Array, @calc_sp
          assert_kind_of Array, @calc_sp.first
        end

        should 'use dates as first elements of sub-arrays' do
          assert_kind_of Date, @calc_sp.first.first
        end

        should 'return floats as second element of sub-arrays' do
          assert_kind_of Float, @calc_sp.first[1]
        end

        should 'return first-of-month as date' do
          assert @calc_sp.collect{ |a| a.first }.all?{ |d| d == d.beginning_of_month } 
        end

        should 'have sort in date order' do
          assert_equal @financial_transaction_1.date.beginning_of_month.to_date, @calc_sp.first.first 
          assert_equal @financial_transaction_2.date.beginning_of_month.to_date, @calc_sp.last.first 
        end

        should 'aggregate transactions for each month' do
          assert_in_delta 199.0+123.45, @calc_sp.first[1], 2 ** -10
        end

        should 'fill in missing months' do
          assert_equal 11-3+1, @calc_sp.size
          assert_equal (@financial_transaction_1.date.beginning_of_month.to_date + 45.days).beginning_of_month.to_date, @calc_sp[1].first
          assert_nil @calc_sp[1][1]
        end

        should "return array of single array if just one transaction" do
          assert_equal [[@unrelated_financial_transaction.date.beginning_of_month.to_date, @unrelated_financial_transaction.value]], @another_supplier.spending_stat.calculated_spend_by_month
        end
      end
      
      context "when there are dates with fuzziness" do
        setup do
          @fuzzy_ft_1 = Factory(:financial_transaction, :date => (@financial_transaction_1.date.beginning_of_month + 14.days), :date_fuzziness => 43, :supplier => @supplier, :value => 99)
          @calc_sp = @spending_stat.calculated_spend_by_month
        end

        should "return entry for every month concerned" do
          assert_equal 10, @calc_sp.size
          assert_equal (@fuzzy_ft_1.date - 30.days).beginning_of_month.to_date, @calc_sp.first.first # spans 3 months so first should be prior month
        end
        
        should "split average across months concerned" do
          assert_in_delta 33.0, @calc_sp.first.last, 2 ** -10
        end
        should "add average to any non-fuzzy transactions" do
          assert_in_delta 33.0+123.45, @calc_sp[1].last, 2 ** -10
        end
        
        context "but still only single month" do
          setup do
            @fuzzy_ft_2 = Factory(:financial_transaction, :date => (@financial_transaction_1.date.beginning_of_month + 14.days), :date_fuzziness => 3, :supplier => @supplier, :value => 66)
            # @calc_sp = 
          end

          should "not raise expection" do
            assert_nothing_raised(Exception) { @spending_stat.calculated_spend_by_month }
          end
        end
      end
      
    end
    
    context "when calculating payee breakdown" do
      setup do
        @organisation = Factory(:council)
        @council = Factory(:another_council)
        @police_authority = Factory(:police_authority)
        @company_1 = Factory(:company)
        @company_2 = Factory(:company)
        @supplier_council = Factory(:supplier, :organisation => @organisation, :payee => @council)
        @supplier_police_authority = Factory(:supplier, :organisation => @organisation, :payee => @police_authority)
        @supplier_company_1 = Factory(:supplier, :organisation => @organisation, :payee => @company_1)
        @supplier_company_2 = Factory(:supplier, :organisation => @organisation, :payee => @company_2)
        @unmatched_supplier = Factory(:supplier, :organisation => @organisation)
        
        @spending_stat_1 = Factory(:spending_stat, :organisation => @organisation)
        
        Factory(:financial_transaction, :supplier => @supplier_council, :value => 123.45)
        Factory(:financial_transaction, :supplier => @supplier_council, :value => 20)
        Factory(:financial_transaction, :supplier => @supplier_police_authority, :value => 40)
        Factory(:financial_transaction, :supplier => @supplier_company_1, :value => 10.5)
        Factory(:financial_transaction, :supplier => @supplier_company_1, :value => 32.1)
        Factory(:financial_transaction, :supplier => @supplier_company_2, :value => 18.1)
        Factory(:financial_transaction, :supplier => @unmatched_supplier, :value => 11.1)
        Factory(:financial_transaction, :supplier => @unmatched_supplier, :value => 1001)
        @unrelated_financial_transaction = Factory(:financial_transaction, :supplier => @another_supplier, :value => 24.5)
      end

      should "return nil if no transactions" do
        assert_nil Factory(:council, :name => 'Foo Council').spending_stat.calculated_payee_breakdown
      end
      
      should "return nil if organisation doesn't respond to financial_transactions" do
        assert_nil Factory(:entity).spending_stat.calculated_payee_breakdown
      end
      
      should "return nil if organisation is a supplier" do
        assert_nil Factory(:supplier).spending_stat.calculated_payee_breakdown
      end
      
      should "return hash of arrays" do
        assert_kind_of Hash, breakdown = @organisation.spending_stat.calculated_payee_breakdown
        assert_kind_of Array, breakdown.first
      end
      
      should "aggregate spend by class" do
        breakdown = @organisation.spending_stat.calculated_payee_breakdown
        assert_in_delta 143.45, breakdown['Council'], 0.1
        assert_in_delta (10.5 + 32.1 + 18.1), breakdown['Company'], 0.1
      end
      
      should "associate unknown entries with nil" do
        breakdown = @organisation.spending_stat.calculated_payee_breakdown
        assert_in_delta 1012.1, breakdown[nil], 0.1
      end
      
    end
  end
  
end

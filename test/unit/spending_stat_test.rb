require 'test_helper'

class SpendingStatTest < ActiveSupport::TestCase
  def setup
    @supplier = Factory(:supplier)
    @spending_stat = Factory(:spending_stat, :organisation => @supplier)
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
    should have_db_column :earliest_transaction
    should have_db_column :latest_transaction
    should have_db_column :transaction_count
    should have_db_column :total_council_spend
    should have_db_column :payer_breakdown
    
    should 'serialize spend_by_month' do
      assert_equal ['foo', 'bar'], Factory(:spending_stat, :spend_by_month => ['foo', 'bar']).reload.spend_by_month 
    end
    
    should 'serialize breakdown' do
      assert_equal ['foo', 'bar'], Factory(:spending_stat, :breakdown => ['foo', 'bar']).reload.breakdown 
    end
    
    should 'serialize payee_breakdown' do
      assert_equal ['foo', 'bar'], Factory(:spending_stat, :payer_breakdown => ['foo', 'bar']).reload.payer_breakdown 
    end
    
  end
  
  context "An instance of the SpendingStat class" do
    
    should "be considered blank when main stat values are blank" do
      new_spending_stat = Factory(:spending_stat)
      assert new_spending_stat.blank?
      new_spending_stat.total_spend = 23
      assert !new_spending_stat.blank?
    end
    
    should "be considered blank when main stat values are all zero" do
      new_spending_stat = Factory(:spending_stat, :total_spend => 0, :average_monthly_spend => 0, :average_transaction_value => 0)
      assert new_spending_stat.blank?
      new_spending_stat.total_spend = 23
      assert !new_spending_stat.blank?
    end
        
    context "when performing" do

      should "should calculate total_spend" do
        @spending_stat.expects(:calculated_total_spend).at_least(1)
        @spending_stat.perform
      end
      
      should "should update with calculated_total_spend" do
        @spending_stat.stubs(:calculated_total_spend).returns(432.1)
        @spending_stat.perform
        assert_equal 432.1, @spending_stat.reload.total_spend
      end

      should "should calculate total_council_spend" do
        @spending_stat.expects(:calculated_total_council_spend).at_least(1)
        @spending_stat.perform
      end
      
      should "should update with calculated_total_council_spend" do
        @spending_stat.stubs(:calculated_total_council_spend).returns(432)
        @spending_stat.perform
        assert_equal 432, @spending_stat.reload.total_council_spend
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

      should "should calculate average_transaction_value" do
        @spending_stat.expects(:calculated_average_transaction_value)
        @spending_stat.perform
      end
      
      should "should update with average_transaction_value" do
        @spending_stat.stubs(:calculated_average_transaction_value).returns(12345)
        @spending_stat.perform
        assert_equal 12345, @spending_stat.reload.average_transaction_value
      end

      should "should set earliest_transaction" do
        earliest_date = 4.weeks.ago.to_date
        @spending_stat.stubs(:calculated_earliest_transaction_date).returns(earliest_date)
        @spending_stat.perform
        assert_equal earliest_date, @spending_stat.reload.earliest_transaction
      end

      should "should set latest_transaction" do
        latest_date = 3.weeks.ago.to_date
        @spending_stat.stubs(:calculated_latest_transaction_date).returns(latest_date)
        @spending_stat.perform
        assert_equal latest_date, @spending_stat.reload.latest_transaction
      end

      should "should set transaction_count" do
        @spending_stat.perform
        assert_equal @spending_stat.organisation.financial_transactions.count, @spending_stat.reload.transaction_count
      end
      
      context "in general" do
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
      
      context "and organisation is company" do
        setup do
          @spending_stat.organisation = Factory(:company)
        end

        should "should not calculate payee breakdown" do
          @spending_stat.expects(:calculated_payee_breakdown).never
          @spending_stat.perform
        end


        should "should calculate payee breakdown" do
          @spending_stat.expects(:calculated_payer_breakdown).at_least_once
          @spending_stat.perform
        end

        should "should update with payee_breakdown" do
          dummy_payee_breakdown = [{:organisation_id => 123, :organisation_type => 'Council'}]
          @spending_stat.stubs(:calculated_payer_breakdown).returns(dummy_payee_breakdown)
          @spending_stat.perform
          assert_equal dummy_payee_breakdown, @spending_stat.reload.breakdown
        end

      end
      
      context "and organisation is charity" do
        setup do
          @spending_stat.organisation = Factory(:charity)
        end

        should "should not calculate payee breakdown" do
          @spending_stat.expects(:calculated_payee_breakdown).never
          @spending_stat.perform
        end


        should "should calculate payee breakdown" do
          @spending_stat.expects(:calculated_payer_breakdown).at_least_once
          @spending_stat.perform
        end

        should "should update with payee_breakdown" do
          dummy_payee_breakdown = [{:organisation_id => 123, :organisation_type => 'Council'}]
          @spending_stat.stubs(:calculated_payer_breakdown).returns(dummy_payee_breakdown)
          @spending_stat.perform
          assert_equal dummy_payee_breakdown, @spending_stat.reload.breakdown
        end

      end

    end

    context "when calculating earliest_transaction_date" do
      should "return first date" do
        assert_equal 11.months.ago.to_date, @spending_stat.calculated_earliest_transaction_date
      end
      
      should "cache result" do
        FinancialTransaction.expects(:find).returns(@financial_transaction_1) #once
        @spending_stat.calculated_earliest_transaction_date
        @spending_stat.calculated_earliest_transaction_date
      end
      
      context "and date has fuzziness" do
        setup do
          @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 23.45, :date => 12.months.ago, :date_fuzziness => 45)
        end

        should "should return date less fuzziness" do
          assert_equal (12.months.ago.to_date - 45.days), @spending_stat.calculated_earliest_transaction_date
        end
      end
    end

    context "when calculating latest_transaction_date" do
      should "return last date" do
        assert_equal 3.months.ago.to_date, @spending_stat.calculated_latest_transaction_date
      end
      
      should "cache result" do
        FinancialTransaction.expects(:find).returns(@financial_transaction_1) #once
        @spending_stat.calculated_latest_transaction_date
        @spending_stat.calculated_latest_transaction_date
      end
      
      context "and date has fuzziness" do
        setup do
          @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 23.45, :date => 2.months.ago, :date_fuzziness => 45)
        end

        should "should return date plus fuzziness" do
          assert_equal (2.months.ago.to_date + 45.days), @spending_stat.calculated_latest_transaction_date
        end
      end
    end
    
    context "when calculating average_transaction_value" do
      should "return total_spend divided by transaction_count" do
        @spending_stat.expects(:calculated_total_spend).at_least_once.returns(12345)
        @spending_stat.expects(:transaction_count).at_least_once.returns(42)
        assert_in_delta (12345/42), @spending_stat.calculated_average_transaction_value, 0.1
      end
      
      should "cache result" do
        @spending_stat.expects(:calculated_total_spend).twice.returns(12345) # called twice per calculated_average_transaction_value
        @spending_stat.expects(:transaction_count).twice.returns(42)
        @spending_stat.calculated_average_transaction_value
        @spending_stat.calculated_average_transaction_value
      end
      
    end
    
    context "when returning months_covered" do
      should "return number of months between earliest_transaction_date and latest_transaction_date" do
        @spending_stat.expects(:earliest_transaction).at_least_once.returns('2010-03-4'.to_date)
        @spending_stat.expects(:latest_transaction).at_least_once.returns('2010-07-26'.to_date)
        assert_equal 5, @spending_stat.months_covered
      end
    end
    
    context "when returning calculated_months_covered" do
      should "return number of months between calculated_earliest_transaction_date and calculated_latest_transaction_date" do
        @spending_stat.expects(:calculated_earliest_transaction_date).at_least_once.returns('2010-03-4'.to_date)
        @spending_stat.expects(:calculated_latest_transaction_date).at_least_once.returns('2010-07-26'.to_date)
        assert_equal 5, @spending_stat.calculated_months_covered
      end
    end
    
    context "when returning transaction_count" do
      context "and transaction_count attribute set" do
        setup do
          @spending_stat[:transaction_count] = 34
        end

        should "return transaction_count attribute" do
          assert_equal 34, @spending_stat.transaction_count
        end
      end
      
      context "and transaction_count not set" do
        setup do
          @spending_stat.transaction_count = nil
          @spending_stat.total_spend = 123
        end

        should "return nil if total_spend nil" do
          #don't bother calculating if we know there's no financial_transactions
          @spending_stat.total_spend = nil
          # @spending_stat.organisation.financial_transactions.delete_all
          assert_nil @spending_stat.transaction_count
        end
        
        should "return calculated transaction_count if total_spend not nil" do
          assert_equal @spending_stat.organisation.financial_transactions.count, @spending_stat.transaction_count
        end
        
        should "update spending_stat with calculated transaction_count" do
          @spending_stat.transaction_count
          assert_equal @spending_stat.organisation.financial_transactions.count, @spending_stat.reload.transaction_count
        end
      end
    end
    
    context "when calculating total_spend" do
      should "sum all financial transactions for organisation" do
        assert_in_delta (123.45 - 32.1 + 22.1), @spending_stat.calculated_total_spend, 2 ** -10
      end
      
      should "cache results" do
        FinancialTransaction.expects(:calculate).returns(42) #once
        @spending_stat.calculated_total_spend
        @spending_stat.calculated_total_spend
      end
    end
    
    context "when calculating total_council_spend" do
      context "when organisation is not a company or charity" do
        should "not calculate total council spending" do
          FinancialTransaction.expects(:sum).never
          @spending_stat.calculated_total_council_spend
        end

        should "return nil" do
          assert_nil @spending_stat.calculated_total_council_spend
        end
      end

      context "when organisation is a company" do
        setup do
          @company = Factory(:company)
        #   @council_supplier = Factory(:supplier, :organisation => Factory(:generic_council), :payee => @company)
        #   @another_council_supplier = Factory(:supplier, :organisation => Factory(:generic_council), :payee => @company)
        #   @non_council_supplier = Factory(:supplier, :payee => @company)
          @company_spending_stat = Factory(:spending_stat, :organisation => @company)
        #   @council_financial_transaction = Factory(:financial_transaction, :supplier => @council_supplier, :value => 444.44)
        #   @another_council_financial_transaction = Factory(:financial_transaction, :supplier => @another_council_supplier, :value => 333.33)
        #   @non_council_financial_transaction = Factory(:financial_transaction, :supplier => @non_council_supplier, :value => 222.2)
        @org_breakdown = [{:organisation_type => 'Council', :organisation_id => 12, :total_spend => 123.4},
                          {:organisation_type => 'PoliceAuthority', :organisation_id => 22, :total_spend => 234},
                          {:organisation_type => 'Council', :organisation_id => 33, :total_spend => 345}]
        end
        
        should "get calculated_payer_breakdown" do
          @company_spending_stat.expects(:calculated_payer_breakdown)
          @company_spending_stat.calculated_total_council_spend
        end

        should "return aggregate of council total_spend" do
          @company_spending_stat.stubs(:calculated_payer_breakdown).returns(@org_breakdown)
          assert_in_delta (123.4 + 345), @company_spending_stat.calculated_total_council_spend, 2 ** -10
        end

        should "cache results" do
          @company_spending_stat.expects(:calculated_payer_breakdown) #once
          @company_spending_stat.calculated_total_council_spend
          @company_spending_stat.calculated_total_council_spend
        end
      end
    end
    
    context "when calculating average_monthly_spend" do

      should "divide calculated_total_of spend for organisation by number of months" do
        assert_in_delta (123.45 - 32.1 + 22.1)/(8+1), @spending_stat.calculated_average_monthly_spend, 2 ** -10 
      end
      
      should "use calculated_months_covered" do
        @spending_stat.expects(:calculated_months_covered).returns(3)
        @spending_stat.calculated_average_monthly_spend
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
          assert_nil Factory(:supplier).create_spending_stat.calculated_spend_by_month
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
          assert_equal [[@unrelated_financial_transaction.date.beginning_of_month.to_date, @unrelated_financial_transaction.value]], @another_supplier.create_spending_stat.calculated_spend_by_month
        end
      end
      
      context "when there are dates with fuzziness" do
        setup do
          @fuzzy_ft_1 = Factory(:financial_transaction, :date => (@financial_transaction_1.date.beginning_of_month + 14.days), :date_fuzziness => 40, :supplier => @supplier, :value => 99)
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
        assert_nil Factory(:council, :name => 'Foo Council').create_spending_stat.calculated_payee_breakdown
      end
      
      should "return nil if organisation doesn't respond to financial_transactions" do
        assert_nil Factory(:entity).create_spending_stat.calculated_payee_breakdown
      end
      
      should "return nil if organisation is a supplier" do
        assert_nil Factory(:supplier).create_spending_stat.calculated_payee_breakdown
      end
      
      should "return hash" do
        assert_kind_of Hash, breakdown = @organisation.create_spending_stat.calculated_payee_breakdown
      end
      
      should "aggregate spend by class" do
        breakdown = @organisation.create_spending_stat.calculated_payee_breakdown
        assert_in_delta 143.45, breakdown['Council'], 0.1
        assert_in_delta (10.5 + 32.1 + 18.1), breakdown['Company'], 0.1
      end
      
      should "associate unknown entries with nil" do
        breakdown = @organisation.spending_stat.calculated_payee_breakdown
        assert_in_delta 1012.1, breakdown[nil], 0.1
      end
    end
    
    context "when updating from financial_transaction" do
      setup do
        @spending_stat = Factory(:spending_stat) # re instantiate, but this time with default organisation, which is council.
        @spend_by_month = [['2009-08-01'.to_date, 2519.0], ['2009-09-01'.to_date, 2519.0], ['2009-10-01'.to_date, nil], ['2009-11-01'.to_date, 5559.5]]
        @spending_stat.update_attributes( :transaction_count => 234,
                                          :total_spend => 12345.6,
                                          :earliest_transaction => '2009-08-21',
                                          :latest_transaction => '2009-11-15',
                                          :spend_by_month => @spend_by_month, 
                                          :average_monthly_spend => 123.45,
                                          :average_transaction_value => 45 )
        @ft = Factory(:financial_transaction, :value => 321.4, :date => '2010-02-08')
        
      end
      
      context "and spending_stat is blank" do
        setup do
          @new_spending_stat = Factory(:spending_stat)
          @new_spending_stat.update_from(@ft)
        end

        should "set total_spend as financial_transaction value" do
          assert_equal @ft.value, @new_spending_stat.total_spend
        end
        
        should "set average monthly spend to financial_transaction value" do
          assert_equal @ft.value, @new_spending_stat.average_monthly_spend
        end
        
        should "set average_transaction_value to financial_transaction value" do
          assert_equal @ft.value, @new_spending_stat.average_transaction_value
        end
        
        should "set transaction_count to 1" do
          assert_equal 1, @new_spending_stat.transaction_count
        end
        
        should "set earliest_transaction to financial_transaction date" do
          assert_equal @ft.date, @new_spending_stat.earliest_transaction
        end
        
        should "set latest_transaction to financial_transaction date" do
          assert_equal @ft.date, @new_spending_stat.latest_transaction
        end
        
        should "use financial_transaction data and value to calculate spend_by_month" do
          assert_equal [ ['2010-02-01'.to_date, 321.4] ], @new_spending_stat.spend_by_month
        end
        
        should "set breakdown to keyed with nil if no payee" do
          assert_equal( {nil => 321.4}, @new_spending_stat.breakdown)
        end
        
        should "set breakdown nil if no organisation is a supplier" do
          supplier_ss = Factory(:spending_stat, :organisation => Factory(:supplier))
          supplier_ss.update_from(@ft)
          assert_nil supplier_ss.breakdown
        end
        
        context "and financial_transaction supplier has payee set" do
          setup do
            @supplier = @ft.supplier
            @supplier.payee = Factory(:police_authority)
            @new_ss = Factory(:spending_stat)
          end

          should "set breakdown to payee type" do
            @new_ss.update_from(@ft)
            assert_equal( {'PoliceAuthority' => 321.4}, @new_ss.breakdown)
          end
        end
        
        context "and spending_stat organisation is a company" do
          setup do
            @supplier = @ft.supplier
            @supplier.payee = Factory(:police_authority)
            @new_ss = Factory(:spending_stat, :organisation => Factory(:company))
          end


          should "set breakdown to supplier organisation details" do
            expected_org_breakdown = [{ :organisation_id => @supplier.organisation_id, 
                                        :organisation_type => @supplier.organisation_type, 
                                        :total_spend => 321.4, 
                                        :transaction_count => 1,
                                        :average_transaction_value => 321.4}]
            @new_ss.update_from(@ft)
            assert_equal expected_org_breakdown, @new_ss.breakdown
          end
        end
      end

      should "increment transaction_count" do
        @spending_stat.update_from(@ft)
        assert_equal 235, @spending_stat.transaction_count
      end

      should "add value to total spend" do
        @spending_stat.update_from(@ft)
        assert_in_delta 12345.6+321.4, @spending_stat.total_spend, 0.1
      end

      should "update latest_transaction with date if financial_transaction date is later" do
        @spending_stat.update_from(@ft)
        assert_equal '2010-02-08'.to_date, @spending_stat.latest_transaction
      end

      should "not update latest_transaction with date if financial_transaction date is earlier" do
        @ft.date = '2009-04-01'
        @spending_stat.update_from(@ft)
        assert_equal '2009-11-15'.to_date, @spending_stat.latest_transaction
      end

      should "update earliest_transaction with date if financial_transaction date is earlier" do
        @ft.date = '2007-04-01'
        @spending_stat.update_from(@ft)
        assert_equal '2007-04-01'.to_date, @spending_stat.earliest_transaction
      end

      should "not update earliest_transaction with date if financial_transaction date is later" do
        @spending_stat.update_from(@ft)
        assert_equal '2009-08-21'.to_date, @spending_stat.earliest_transaction
      end

      should "update average_transaction_value with recalculated average_transaction_value" do
        @spending_stat.update_from(@ft)
        assert_in_delta (12345.6+321.4)/235, @spending_stat.average_transaction_value, 0.1
      end

      should "add financial_transaction value to spend_by_month, filling in gaps" do
        expected_new_spend_by_month = @spend_by_month + [['2009-12-01'.to_date, nil], ['2010-01-01'.to_date, nil], ['2010-02-01'.to_date, 321.4]]
        @spending_stat.update_from(@ft)
        
        assert_equal expected_new_spend_by_month, @spending_stat.spend_by_month 
      end
      
      should "update breakdown with payee breakdown" do
        @spending_stat.update_attributes(:breakdown => {'Company' => 111.1}, :total_spend => 111.1)
        @spending_stat.update_from(@ft)
        assert_equal( {'Company' => 111.1, nil => 321.4}, @spending_stat.breakdown)
        @spending_stat.update_from(@ft)
        assert_equal( {'Company' => 111.1, nil => 642.8}, @spending_stat.breakdown)
      end
      
      context "and spending_stat organisation is a company" do
        setup do
          @company = Factory(:company)
          @new_ss = Factory(:spending_stat, :organisation => @company)
        end

        should "update breakdown with organisation breakdown" do
          @organisation = @ft.supplier.organisation
          @another_org = Factory(:generic_council)
          expected_org_breakdown = [{ :organisation_id => @organisation.id, 
                                      :organisation_type => @organisation.class.to_s, 
                                      :total_spend => 321.4, 
                                      :transaction_count => 1,
                                      :average_transaction_value => 321.4}]
          expected_org_breakdown_2 = [{ :organisation_id => @organisation.id, 
                                        :organisation_type => @organisation.class.to_s, 
                                        :total_spend => 642.8, 
                                        :transaction_count => 2,
                                        :average_transaction_value => 321.4}]
          expected_org_breakdown_3 = expected_org_breakdown_2 + 
                                     [{ :organisation_id => @another_org.id, 
                                        :organisation_type => @another_org.class.to_s, 
                                        :total_spend => 321.4, 
                                        :transaction_count => 1,
                                        :average_transaction_value => 321.4}]
          @new_ss.update_from(@ft)
          assert_equal expected_org_breakdown, @new_ss.breakdown
          
          @new_ss.update_from(@ft)
          assert_equal expected_org_breakdown_2, @new_ss.breakdown
          @ft.supplier.organisation = @another_org
          @new_ss.update_from(@ft)
          assert_equal expected_org_breakdown_3, @new_ss.breakdown
        end
      end
      
      context "and spending_stat organisation is a charity" do
        setup do
          @charity = Factory(:charity)
          @new_ss = Factory(:spending_stat, :organisation => @charity)
        end

        should "update breakdown with organisation breakdown" do
          @organisation = @ft.supplier.organisation
          @another_org = Factory(:generic_council)
          expected_org_breakdown = [{ :organisation_id => @organisation.id, 
                                      :organisation_type => @organisation.class.to_s, 
                                      :total_spend => 321.4, 
                                      :transaction_count => 1,
                                      :average_transaction_value => 321.4}]
          expected_org_breakdown_2 = [{ :organisation_id => @organisation.id, 
                                        :organisation_type => @organisation.class.to_s, 
                                        :total_spend => 642.8, 
                                        :transaction_count => 2,
                                        :average_transaction_value => 321.4}]
          expected_org_breakdown_3 = expected_org_breakdown_2 + 
                                     [{ :organisation_id => @another_org.id, 
                                        :organisation_type => @another_org.class.to_s, 
                                        :total_spend => 321.4, 
                                        :transaction_count => 1,
                                        :average_transaction_value => 321.4}]
          @new_ss.update_from(@ft)
          assert_equal expected_org_breakdown, @new_ss.breakdown
          
          @new_ss.update_from(@ft)
          assert_equal expected_org_breakdown_2, @new_ss.breakdown
          @ft.supplier.organisation = @another_org
          @new_ss.update_from(@ft)
          assert_equal expected_org_breakdown_3, @new_ss.breakdown
        end
      end
      
      
      context "and financial_transaction date is month with existing value" do
        setup do
          @ft.date = '2009-09-10'
          @spending_stat.update_from(@ft)
        end

        should "add value to existing value" do
          expected_new_spend_by_month = [['2009-08-01'.to_date, 2519.0], ['2009-09-01'.to_date, 2519.0+321.4], ['2009-10-01'.to_date, nil], ['2009-11-01'.to_date, 5559.5]]
          assert_equal expected_new_spend_by_month, @spending_stat.spend_by_month
        end
      end
      
      context "and financial_transaction date is prior to existing months" do
        setup do
          @ft.date = '2009-06-10'
        end

        should "add financial_transaction value to spend_by_month, filling in gaps" do
          expected_new_spend_by_month = [['2009-06-01'.to_date, 321.4], ['2009-07-01'.to_date, nil]] + @spend_by_month
          @spending_stat.update_from(@ft)

          assert_equal expected_new_spend_by_month, @spending_stat.spend_by_month 
        end
      end
      
      context "and financial_transaction supplier has payee set" do
        setup do
          @supplier = @ft.supplier
          @supplier.payee = Factory(:police_authority)
          @new_ss = Factory(:spending_stat, :breakdown => {'Company' => 111.1}, 
                                            :total_spend => 111.1, 
                                            :earliest_transaction => 3.months.ago.to_date, 
                                            :latest_transaction => 1.month.ago.to_date, 
                                            :spend_by_month => [['2009-08-01'.to_date, 111.1]] )
        end

        should "update breakdown" do
          @new_ss.update_from(@ft)
          assert_equal( {'Company' => 111.1, 'PoliceAuthority' => 321.4}, @new_ss.breakdown)
          @new_ss.update_from(@ft)
          assert_equal( {'Company' => 111.1, 'PoliceAuthority' => 642.8}, @new_ss.breakdown)
        end
      end
      
      context "and just one existing month" do
        setup do
          @new_ss = Factory(:spending_stat)
          @new_ss.update_from(@ft)
        end

        should "update without exceptions" do
          assert_nothing_raised(Exception) { @new_ss.update_from(@ft) }
        end
      end
    end
    
    context "when calculating payer_breakdown" do
      setup do
        @company = Factory(:company)
        @councils = (1..20).collect do
          c = Factory(:generic_council)
          s = Factory(:supplier, :organisation => c, :payee => @company)
          Factory(:financial_transaction, :supplier => s, :value => 12)
          s.create_spending_stat.perform
          c.create_spending_stat.perform
          c
        end
        @bd_spending_stat = Factory(:spending_stat, :organisation => @company)
        @first_council = @councils.first
        @second_supplier = Factory(:supplier, :organisation => @first_council, :payee => @company)
        Factory(:financial_transaction, :supplier => @second_supplier, :value => 101)
        @second_supplier.create_spending_stat.perform
        @breakdown = @bd_spending_stat.calculated_payer_breakdown
      end

      should "return an array of hashes" do
        assert_kind_of Array, @breakdown
        assert_kind_of Hash, @breakdown.first
      end
      
      should "cache result" do
        @company.expects(:supplying_relationships).never #already called once in setup
        @bd_spending_stat.calculated_payer_breakdown
      end
      
      should "have one hash per council" do
        assert_equal 20, @breakdown.size
      end
      
      context "and hash" do
        setup do
          @council_hash = @breakdown.detect{ |h| h[:organisation_id] == @first_council.id }
        end
        
        should "contain organisation id" do
          assert @council_hash[:organisation_id]
        end
        should "contain organisation type" do
          assert_equal 'Council', @council_hash[:organisation_type]
        end
        should "contain aggregate of supplier total spend" do
          assert_equal 113, @council_hash[:total_spend]
        end
        
        # should_eventually "contain average_monthly_spend" do
        #   assert @first_council.spending_stat.total_spend,  @council_hash[:average_monthly_spend]
        # end
        
        should "contain aggregate of supplier transaction_count" do
          assert_equal 2, @council_hash[:transaction_count]
        end
        should "calculate average_transaction_size from total_spend and transaction_count" do
          assert_in_delta 113.0/2, @council_hash[:average_transaction_size], 0.1
        end
      end
      
    end
  end
  
end

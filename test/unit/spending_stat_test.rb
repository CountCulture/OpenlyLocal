require File.expand_path('../../test_helper', __FILE__)

class SpendingStatTest < ActiveSupport::TestCase
  def setup
    @payer_and_payee = Factory(:entity)
    @supplier = Factory(:supplier, :organisation => @payer_and_payee)
    @spending_stat = Factory(:spending_stat, :organisation => @supplier)
    @payer_and_payee.spending_stat = Factory(:spending_stat, :organisation => @payer_and_payee)
    @payee_supplier = Factory(:supplier, :payee => @payer_and_payee)
    @another_supplier = Factory(:supplier, :organisation => @payer_and_payee)
    @payment_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 123.45, :date => 11.months.ago)
    @payment_2 = Factory(:financial_transaction, :supplier => @supplier, :value => -32.1, :date => 3.months.ago)
    @payment_3 = Factory(:financial_transaction, :supplier => @supplier, :value => 22.1, :date => 5.months.ago)
    @payment_4 = Factory(:financial_transaction, :supplier => @another_supplier, :value => 33.8, :date => 8.months.ago)
    @receipt_1 = Factory(:financial_transaction, :supplier => @payee_supplier, :value => 44.4, :date => 4.months.ago)
    @company = Factory(:company)
    company_supplier = Factory(:supplier, :payee => @company)
    Factory(:financial_transaction, :supplier => company_supplier)
  end
  
  context "The SpendingStat class" do

    should belong_to :organisation
    should validate_presence_of :organisation_type
    should validate_presence_of :organisation_id

    [ :total_spend, :average_monthly_spend, :average_transaction_value,
      :spend_by_month, :breakdown, :earliest_transaction, :latest_transaction,
      :transaction_count, :total_received, :total_received_from_councils,
      :payer_breakdown,
    ].each do |column|
      should have_db_column column
    end
    
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
      new_spending_stat.attributes = {:total_spend => nil, :total_received => 23}
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

      should "should calculate total_receivedd" do
        @spending_stat.expects(:calculated_total_received).at_least(1)
        @spending_stat.perform
      end
      
      should "should update with calculated_total_spend" do
        @spending_stat.stubs(:calculated_total_received).returns(432)
        @spending_stat.perform
        assert_equal 432, @spending_stat.reload.total_received
      end

      should "should calculate total_received_from_councils" do
        @spending_stat.expects(:calculated_total_received_from_councils).at_least(1)
        @spending_stat.perform
      end
      
      should "should update with calculated_total_received_from_councils" do
        @spending_stat.stubs(:calculated_total_received_from_councils).returns(432)
        @spending_stat.perform
        assert_equal 432, @spending_stat.reload.total_received_from_councils
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

      should "should calculate payer breakdown" do
        @spending_stat.expects(:calculated_payer_breakdown).at_least_once
        @spending_stat.perform
      end

      should "should update with payer_breakdown" do
        dummy_payee_breakdown = [{:organisation_id => 123, :organisation_type => 'Council'}]
        @spending_stat.stubs(:calculated_payer_breakdown).returns(dummy_payee_breakdown)
        @spending_stat.perform
        assert_equal dummy_payee_breakdown, @spending_stat.reload.payer_breakdown
      end
      
    end

    context "when calculating earliest_transaction_date" do
      should "return first date" do
        assert_equal 11.months.ago.to_date, @spending_stat.calculated_earliest_transaction_date
      end
      
      should "cache result" do
        FinancialTransaction.expects(:find).returns(@payment_1) #once
        @spending_stat.calculated_earliest_transaction_date
        @spending_stat.calculated_earliest_transaction_date
      end
      
      should "return nil if no payments" do
        assert_nil Factory(:entity).create_spending_stat.calculated_earliest_transaction_date
      end
      
      should "return nil if no payments method" do
        assert_nil Factory(:company).create_spending_stat.calculated_earliest_transaction_date
      end
      
      context "and date has fuzziness" do
        setup do
          @payment_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 23.45, :date => 12.months.ago, :date_fuzziness => 45)
        end

        should "should return date less fuzziness" do
          assert_equal (12.months.ago.to_date - 45.days), @spending_stat.calculated_earliest_transaction_date
        end
      end
      
      context "and spending_stat organisation has payments and payments received" do
        setup do
          @payment_received = Factory(:financial_transaction, :supplier => @payee_supplier, :date => 3.years.ago)
        end
      
        should "should return date of earliest payment, ignoring payment_received" do
          assert_equal @payment_1.date.to_date, @spending_stat.calculated_earliest_transaction_date
        end
      end
    end

    context "when calculating latest_transaction_date" do
      should "return last date" do
        assert_equal 3.months.ago.to_date, @spending_stat.calculated_latest_transaction_date
      end
      
      should "cache result" do
        FinancialTransaction.expects(:find).returns(@payment_1) #once
        @spending_stat.calculated_latest_transaction_date
        @spending_stat.calculated_latest_transaction_date
      end
      
      should "return nil if no payments" do
        assert_nil Factory(:entity).create_spending_stat.calculated_latest_transaction_date
      end
      
      should "return nil if no payments method" do
        assert_nil Factory(:company).create_spending_stat.calculated_latest_transaction_date
      end
      
      context "and date has fuzziness" do
        setup do
          @payment_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 23.45, :date => 2.months.ago, :date_fuzziness => 45)
        end

        should "should return date plus fuzziness" do
          assert_equal (2.months.ago.to_date + 45.days), @spending_stat.calculated_latest_transaction_date
        end
      end
      
      context "and spending_stat organisation has payments and payments received" do
        setup do
          @payment_received = Factory(:financial_transaction, :supplier => @payee_supplier, :date => 3.days.ago)
        end
      
        should "should return date of earliest payment, ignoring payment_received" do
          assert_equal @payment_2.date.to_date, @spending_stat.calculated_latest_transaction_date
        end
      end
    end
    
    context "when calculating average_transaction_value" do
      should "return total_spend divided by transaction_count" do
        @spending_stat.expects(:calculated_total_spend).at_least_once.returns(12345)
        @spending_stat.expects(:calculated_transaction_count).at_least_once.returns(42)
        assert_in_delta (12345/42), @spending_stat.calculated_average_transaction_value, 0.1
      end
      
      should "cache result" do
        @spending_stat.expects(:calculated_total_spend).twice.returns(12345) # called twice per calculated_average_transaction_value
        @spending_stat.expects(:calculated_transaction_count).twice.returns(42)
        @spending_stat.calculated_average_transaction_value
        @spending_stat.calculated_average_transaction_value
      end
      
      should "return nil if transaction_count is nil" do
        @spending_stat.stubs(:calculated_total_spend).returns(12345) # called twice per calculated_average_transaction_value
        @spending_stat.stubs(:calculated_transaction_count) # => nil
        assert_nil @spending_stat.calculated_average_transaction_value
      end
      
      should "return nil if calculated_total_spend is nil" do
        @spending_stat.stubs(:calculated_total_spend) # => nil
        @spending_stat.stubs(:calculated_transaction_count).returns(42)
        assert_nil @spending_stat.calculated_average_transaction_value
      end
      
      should "return nil if transaction_count is 0" do
        @spending_stat.stubs(:calculated_total_spend).returns(12345.0) # called twice per calculated_average_transaction_value
        @spending_stat.stubs(:calculated_transaction_count).returns(0)
        assert_nil @spending_stat.calculated_average_transaction_value
      end
    end
    
    context "when returning months_covered" do
      should "return number of months between earliest_transaction_date and latest_transaction_date" do
        @spending_stat.expects(:earliest_transaction).at_least_once.returns('2010-03-4'.to_date)
        @spending_stat.expects(:latest_transaction).at_least_once.returns('2010-07-26'.to_date)
        assert_equal 5, @spending_stat.months_covered
      end
      
      should "return nil if no earliest_transaction_date" do
        @spending_stat.stubs(:latest_transaction).returns('2010-03-4'.to_date)
        @spending_stat.stubs(:earliest_transaction) # => nil
        assert_nil @spending_stat.months_covered
      end
      
      should "return nil if no latest_transaction_date" do
        @spending_stat.stubs(:earliest_transaction).returns('2010-03-4'.to_date)
        @spending_stat.stubs(:latest_transaction) # => nil
        assert_nil @spending_stat.months_covered
      end
    end
    
    context "when returning number of councils" do
      should "return nil by default" do
        assert_nil @spending_stat.number_of_councils
      end
      
      should "return number of councils listed in payer_breakdown" do
        @spending_stat.payer_breakdown = [{:organisation_type => 'Council', :organisation_id => 12, :total_spend => 123.4},
                                          {:organisation_type => 'PoliceAuthority', :organisation_id => 22, :total_spend => 234},
                                          {:organisation_type => 'Council', :organisation_id => 33, :total_spend => 345}]
        assert_equal 2, @spending_stat.number_of_councils
      end
    end
    
    context "when returning biggest_council" do
      should "return nil by default" do
        assert_nil @spending_stat.biggest_council
      end
      
      should "return biggest of council listed in payer_breakdown" do
        @council_1 = Factory(:generic_council)
        @council_2 = Factory(:generic_council)
        @entity = Factory(:entity)
        @spending_stat.payer_breakdown = [{:organisation_type => 'Council', :organisation_id => @council_1.id, :total_spend => 123.4},
                                          {:organisation_type => 'Entity', :organisation_id => @entity.id, :total_spend => 1234},
                                          {:organisation_type => 'Council', :organisation_id => @council_2.id, :total_spend => 345}]
        assert_equal @council_2, @spending_stat.biggest_council
      end
      
      should "return nil if no councils listed in payer_breakdown" do
        @entity = Factory(:entity)
        @spending_stat.payer_breakdown = [{:organisation_type => 'Entity', :organisation_id => @entity.id, :total_spend => 1234}]
        assert_nil @spending_stat.biggest_council
      end
    end
    
    context "when returning calculated_months_covered" do
      should "return number of months between calculated_earliest_transaction_date and calculated_latest_transaction_date" do
        @spending_stat.expects(:calculated_earliest_transaction_date).at_least_once.returns('2010-03-4'.to_date)
        @spending_stat.expects(:calculated_latest_transaction_date).at_least_once.returns('2010-07-26'.to_date)
        assert_equal 5, @spending_stat.calculated_months_covered
      end
      
      should "return nil if no calculated_earliest_transaction_date" do
        @spending_stat.stubs(:calculated_latest_transaction_date).returns('2010-03-4'.to_date)
        @spending_stat.stubs(:calculated_earliest_transaction_date) # => nil
        assert_nil @spending_stat.calculated_months_covered
      end
      
      should "return nil if no calculated_latest_transaction_date" do
        @spending_stat.stubs(:calculated_earliest_transaction_date).returns('2010-03-4'.to_date)
        @spending_stat.stubs(:calculated_latest_transaction_date) # => nil
        assert_nil @spending_stat.calculated_months_covered
      end
    end
    
    context "when calculating transaction_count" do
      should "return count of payments" do
        assert_equal 4, @payer_and_payee.spending_stat.calculated_transaction_count
      end
      
      should "cache calculated_transaction_count" do
        FinancialTransaction.expects(:count).returns(42) # once
        @payer_and_payee.spending_stat.calculated_transaction_count
        @payer_and_payee.spending_stat.calculated_transaction_count
      end
      
      should "return nil if spending_stat organisation doesn't have payments method" do
        assert_nil Factory(:company).create_spending_stat.calculated_transaction_count
      end

    end
    
    context "when calculating total_spend" do
      
      should "cache results" do
        FinancialTransaction.expects(:calculate).returns(42) #once
        @spending_stat.calculated_total_spend
        @spending_stat.calculated_total_spend
      end
      
      should "sum payments, ignoring receipts" do
        assert_in_delta (123.45 - 32.1 + 22.1 + 33.8), @payer_and_payee.spending_stat.calculated_total_spend, 2 ** -10
      end
      
      context "and spending_stat organisation is a supplier" do
        should "sum all associated financial_transactions" do
          assert_in_delta (123.45 - 32.1 + 22.1), @spending_stat.calculated_total_spend, 2 ** -10
        end
      end
      
      context "and spending_stat organisation has no payments" do
        should "return nil" do
          assert_nil Factory(:company).create_spending_stat.calculated_total_spend
        end
      end
    end
    
    context "when calculating total received" do
      setup do
        @another_payment_to_payee = Factory(:financial_transaction, :supplier => @payee_supplier, :value => 111.1, :date => 11.months.ago)        
      end
      
      should "sum all payments received" do
        assert_in_delta (111.1 + 44.4), @payer_and_payee.spending_stat.calculated_total_received, 2 ** -10
      end
      
      should "cache results" do
        FinancialTransaction.expects(:calculate).returns(42) #once
        @payer_and_payee.spending_stat.calculated_total_received
        @payer_and_payee.spending_stat.calculated_total_received
      end
      
      should "return 0 if no payments received" do
        assert_equal 0.0, Factory(:entity).create_spending_stat.calculated_total_received
      end
      
    end
    
    context "when calculating total_received_from_councils" do
      setup do
        @org_breakdown = [{:organisation_type => 'Council', :organisation_id => 12, :total_spend => 123.4},
                          {:organisation_type => 'PoliceAuthority', :organisation_id => 22, :total_spend => 234},
                          {:organisation_type => 'Council', :organisation_id => 33, :total_spend => 345}]
        @company = Factory(:company)
        @company_spending_stat = Factory(:spending_stat, :organisation => @company)
      end
      
      should "get calculated_payer_breakdown" do
        @spending_stat.expects(:calculated_payer_breakdown)
        @spending_stat.calculated_total_received_from_councils
      end

      should "return aggregate of council total_spend" do
        @spending_stat.stubs(:calculated_payer_breakdown).returns(@org_breakdown)
        assert_in_delta (123.4 + 345), @spending_stat.calculated_total_received_from_councils, 2 ** -10
      end

      should "cache results" do
        @spending_stat.expects(:calculated_payer_breakdown).twice #only. Each method calls calculated_payer_breakdown twice
        @spending_stat.calculated_total_received_from_councils
        @spending_stat.calculated_total_received_from_councils
      end
      
      context "and calculated_payer_breakdown is blank" do
        should "return nil" do
          @spending_stat.stubs(:calculated_payer_breakdown)# returns nil
          assert_nil @spending_stat.calculated_total_received_from_councils
        end
      end

      # context "when organisation is a company" do
      #   setup do
      #     @company = Factory(:company)
      #   #   @council_supplier = Factory(:supplier, :organisation => Factory(:generic_council), :payee => @company)
      #   #   @another_council_supplier = Factory(:supplier, :organisation => Factory(:generic_council), :payee => @company)
      #   #   @non_council_supplier = Factory(:supplier, :payee => @company)
      #     @company_spending_stat = Factory(:spending_stat, :organisation => @company)
      #   #   @council_financial_transaction = Factory(:financial_transaction, :supplier => @council_supplier, :value => 444.44)
      #   #   @another_council_financial_transaction = Factory(:financial_transaction, :supplier => @another_council_supplier, :value => 333.33)
      #   #   @non_council_financial_transaction = Factory(:financial_transaction, :supplier => @non_council_supplier, :value => 222.2)
      #   @org_breakdown = [{:organisation_type => 'Council', :organisation_id => 12, :total_spend => 123.4},
      #                     {:organisation_type => 'PoliceAuthority', :organisation_id => 22, :total_spend => 234},
      #                     {:organisation_type => 'Council', :organisation_id => 33, :total_spend => 345}]
      #   end
      #   
      #   should "get calculated_payer_breakdown" do
      #     @company_spending_stat.expects(:calculated_payer_breakdown)
      #     @company_spending_stat.calculated_total_received_from_councils
      #   end
      # 
      #   should "return aggregate of council total_spend" do
      #     @company_spending_stat.stubs(:calculated_payer_breakdown).returns(@org_breakdown)
      #     assert_in_delta (123.4 + 345), @company_spending_stat.calculated_total_received_from_councils, 2 ** -10
      #   end
      # 
      #   should "cache results" do
      #     @company_spending_stat.expects(:calculated_payer_breakdown) #once
      #     @company_spending_stat.calculated_total_received_from_councils
      #     @company_spending_stat.calculated_total_received_from_councils
      #   end
      # end
    end
    
    context "when calculating average_monthly_spend" do

      should "divide calculated_total_of spend for organisation by number of months" do
        assert_in_delta (123.45 - 32.1 + 22.1)/(8+1), @spending_stat.calculated_average_monthly_spend, 2 ** -10 
      end
      
      should "use calculated_months_covered" do
        @spending_stat.expects(:calculated_months_covered).at_least_once.returns(3)
        @spending_stat.calculated_average_monthly_spend
      end
      
      should "return nil when no payments" do
        assert_nil Factory(:spending_stat).calculated_average_monthly_spend
      end
      
      should "return nil when spending_stat organisation doesn't have payments method" do
        assert_nil Factory(:company).create_spending_stat.calculated_average_monthly_spend
      end
      
      should "return nil when no calculated_months_covered" do
        @spending_stat.expects(:calculated_months_covered)# => nil
        assert_nil @spending_stat.calculated_average_monthly_spend
      end
    end
    
    context "when calculating spend_by_month" do
      context "in general" do
        setup do
          @new_ft = Factory(:financial_transaction, :date => (@payment_1.date.beginning_of_month + 8.days), :supplier => @supplier, :value => 199)
          @calc_sp = @spending_stat.calculated_spend_by_month
        end
        
        should 'return nil if no transactions' do
          assert_nil Factory(:supplier).create_spending_stat.calculated_spend_by_month
        end

        should "return nil if spending_stat organisation doesn't respond to payments" do
          assert_nil @company.create_spending_stat.calculated_spend_by_month
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
          assert_equal @payment_1.date.beginning_of_month.to_date, @calc_sp.first.first 
          assert_equal @payment_2.date.beginning_of_month.to_date, @calc_sp.last.first 
        end

        should 'aggregate transactions for each month' do
          assert_in_delta 199.0+123.45, @calc_sp.first[1], 2 ** -10
        end

        should 'fill in missing months' do
          assert_equal 11-3+1, @calc_sp.size
          assert_equal (@payment_1.date.beginning_of_month.to_date + 45.days).beginning_of_month.to_date, @calc_sp[1].first
          assert_nil @calc_sp[1][1]
        end

        should "return array of single array if just one transaction" do
          calc_sp = @another_supplier.create_spending_stat.calculated_spend_by_month
          assert_equal @payment_4.date.beginning_of_month.to_date, calc_sp.first.first
          assert_in_delta @payment_4.value, calc_sp.first.last, 0.01
          # assert_equal [[@payment_4.date.beginning_of_month.to_date, @payment_4.value]], @another_supplier.create_spending_stat.calculated_spend_by_month
        end
      end
      
      context "when there are dates with fuzziness" do
        setup do
          @fuzzy_ft_1 = Factory(:financial_transaction, :date => (@payment_1.date.beginning_of_month + 14.days), :date_fuzziness => 40, :supplier => @supplier, :value => 99)
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
            @fuzzy_ft_2 = Factory(:financial_transaction, :date => (@payment_1.date.beginning_of_month + 14.days), :date_fuzziness => 3, :supplier => @supplier, :value => 66)
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
        @unrelated_payment = Factory(:financial_transaction, :supplier => @another_supplier, :value => 24.5)
      end

      should "return nil if no payments" do
        assert_nil Factory(:council, :name => 'Foo Council').create_spending_stat.calculated_payee_breakdown
      end
      
      should "return nil if organisation doesn't respond to payments" do
        assert_nil @company.create_spending_stat.calculated_payee_breakdown
      end
      
      should "return nil if organisation is a supplier" do
        assert_nil @payee_supplier.create_spending_stat.calculated_payee_breakdown
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
      
      context "and financial_transaction was paid by spending_stat organisation" do
        setup do
          @ft = Factory(:financial_transaction, :value => 321.4, :date => '2010-02-08', :supplier => @supplier)
        end

        context "and spending_stat is blank" do

          setup do
            @new_spending_stat = @supplier.organisation.spending_stat
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
              # @supplier = @ft.supplier
              # @supplier.payee = Factory(:police_authority)
              # @new_ss = Factory(:spending_stat)
              @new_ss = @payee_supplier.organisation.create_spending_stat
            end

            should "set breakdown to payee type" do
              @new_ss.update_from(@receipt_1)
              assert_equal( {'Entity' => @receipt_1.value}, @new_ss.breakdown)
            end
          end
        end
        
        context "and spending_stat is not blank" do
          setup do
            @spending_stat = @supplier.organisation.spending_stat
            @spend_by_month = [['2009-08-01'.to_date, 2519.0], ['2009-09-01'.to_date, 2519.0], ['2009-10-01'.to_date, nil], ['2009-11-01'.to_date, 5559.5]]
            @spending_stat.update_attributes( :transaction_count => 234,
                                              :total_spend => 12345.6,
                                              :earliest_transaction => '2009-08-21',
                                              :latest_transaction => '2009-11-15',
                                              :spend_by_month => @spend_by_month, 
                                              :average_monthly_spend => 123.45,
                                              :average_transaction_value => 45 )
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
        end
      end
      
      context "and spending_stat organisation is supplier" do
        setup do
          @ft = Factory(:financial_transaction, :value => 321.4, :date => '2010-02-08', :supplier => @supplier)
        end

        context "and spending_stat is blank" do

          setup do
            @new_spending_stat = @supplier.spending_stat
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

          should "set breakdown to nil" do
            assert_nil @new_spending_stat.breakdown
          end
        end
        
        context "and spending_stat is not blank" do
          setup do
            @new_spending_stat = @supplier.spending_stat
            @spend_by_month = [['2009-08-01'.to_date, 2519.0], ['2009-09-01'.to_date, 2519.0], ['2009-10-01'.to_date, nil], ['2009-11-01'.to_date, 5559.5]]
            @new_spending_stat.update_attributes( :transaction_count => 234,
                                              :total_spend => 12345.6,
                                              :earliest_transaction => '2009-08-21',
                                              :latest_transaction => '2009-11-15',
                                              :spend_by_month => @spend_by_month, 
                                              :average_monthly_spend => 123.45,
                                              :average_transaction_value => 45 )
          end

          should "increment transaction_count" do
            @new_spending_stat.update_from(@ft)
            assert_equal 235, @new_spending_stat.transaction_count
          end

          should "add value to total spend" do
            @new_spending_stat.update_from(@ft)
            assert_in_delta 12345.6+321.4, @new_spending_stat.total_spend, 0.1
          end

          should "update latest_transaction with date if financial_transaction date is later" do
            @new_spending_stat.update_from(@ft)
            assert_equal '2010-02-08'.to_date, @new_spending_stat.latest_transaction
          end

          should "not update latest_transaction with date if financial_transaction date is earlier" do
            @ft.date = '2009-04-01'
            @new_spending_stat.update_from(@ft)
            assert_equal '2009-11-15'.to_date, @new_spending_stat.latest_transaction
          end

          should "update earliest_transaction with date if financial_transaction date is earlier" do
            @ft.date = '2007-04-01'
            @new_spending_stat.update_from(@ft)
            assert_equal '2007-04-01'.to_date, @new_spending_stat.earliest_transaction
          end

          should "not update earliest_transaction with date if financial_transaction date is later" do
            @new_spending_stat.update_from(@ft)
            assert_equal '2009-08-21'.to_date, @new_spending_stat.earliest_transaction
          end

          should "update average_transaction_value with recalculated average_transaction_value" do
            @new_spending_stat.update_from(@ft)
            assert_in_delta (12345.6+321.4)/235, @new_spending_stat.average_transaction_value, 0.1
          end

          should "add financial_transaction value to spend_by_month, filling in gaps" do
            expected_new_spend_by_month = @spend_by_month + [['2009-12-01'.to_date, nil], ['2010-01-01'.to_date, nil], ['2010-02-01'.to_date, 321.4]]
            @new_spending_stat.update_from(@ft)

            assert_equal expected_new_spend_by_month, @new_spending_stat.spend_by_month 
          end

          should "return nil for breakdown" do
            @new_spending_stat.update_from(@ft)
            assert_nil @new_spending_stat.breakdown
          end
        end
      end
      
      context "and financial_transaction was not paid by spending_stat organisation" do
        setup do
          # @supplier = @ft.supplier
          # @supplier.payee = Factory(:police_authority)
          # @company_ss = @company.create_spending_stat
          # @receipt_1
          @new_spending_stat = @payer_and_payee.spending_stat
        end
      
        context "and spending_stat is blank" do

          setup do
            @new_spending_stat = @supplier.organisation.spending_stat
            @new_spending_stat.update_from(@receipt_1)
          end

          should "not set total_spend" do
            assert_nil @new_spending_stat.total_spend
          end

          should "not set average monthly spend" do
            assert_nil @new_spending_stat.average_monthly_spend
          end

          should "not set average_transaction_value" do
            assert_nil @new_spending_stat.average_transaction_value
          end

          should "not set transaction_count" do
            assert_nil @new_spending_stat.transaction_count
          end

          should "not set earliest_transaction" do
            assert_nil @new_spending_stat.earliest_transaction
          end

          should "not set latest_transaction" do
            assert_nil @new_spending_stat.latest_transaction
          end

          should "not set spend_by_month" do
            assert_nil @new_spending_stat.spend_by_month
          end

          should "not set breakdown" do
            assert_nil @new_spending_stat.breakdown
          end

          should "set total_received to be integer value of transaction" do
            assert_equal 44, @new_spending_stat.total_received
          end

          should "not set total_received_from_councils if payer is not a council" do
            assert_nil @new_spending_stat.total_received_from_councils
          end

          should "set total_received_from_councils to be integer value of transaction if payer is a council" do
            @new_spending_stat = @supplier.organisation.create_spending_stat # create new one
            @receipt_1.supplier.organisation = Factory(:generic_council)
            @new_spending_stat.update_from(@receipt_1)
            assert_equal 44, @new_spending_stat.total_received_from_councils
          end

          should "set payer_breakdown to supplier organisation details" do
            expected_org_breakdown = [{ :organisation_id => @payee_supplier.organisation_id, 
                                        :organisation_type => @payee_supplier.organisation_type, 
                                        :total_spend => 44.4, 
                                        :transaction_count => 1,
                                        :average_transaction_value => 44.4}]
            assert_equal expected_org_breakdown, @new_spending_stat.payer_breakdown
          end
        end
        
        context "and spending_stat is not blank" do
          setup do
            @new_spending_stat = @supplier.organisation.spending_stat
            @new_spending_stat.update_from(@receipt_1) # set up initial values
            @another_org = Factory(:generic_council)
            
            @expected_org_breakdown_1 = [{ :organisation_id => @payee_supplier.organisation_id, 
                                          :organisation_type => @payee_supplier.organisation_type, 
                                          :total_spend => 88.8, 
                                          :transaction_count => 2,
                                          :average_transaction_value => 44.4}]
            @expected_org_breakdown_2 = @expected_org_breakdown_1 + 
                                       [{ :organisation_id => @another_org.id, 
                                          :organisation_type => @another_org.class.to_s, 
                                          :total_spend => 44.4, 
                                          :transaction_count => 1,
                                          :average_transaction_value => 44.4}]
            
          end

          should "update total_received" do
            @new_spending_stat.update_from(@receipt_1) # set up initial values
            assert_equal 88, @new_spending_stat.total_received
          end
          
          should "update total_received_from_councils if supplier organisation is a council" do
            @receipt_1.supplier.organisation = Factory(:generic_council)
            @new_spending_stat.update_from(@receipt_1)
            assert_equal 44, @new_spending_stat.total_received_from_councils # was nil
            @new_spending_stat.update_from(@receipt_1)
            assert_equal 88, @new_spending_stat.total_received_from_councils
          end

          should "not update total_received_from_councils if supplier organisation is not a council" do
            @new_spending_stat.update_attribute(:total_received_from_councils, 21)
            @new_spending_stat.update_from(@receipt_1)
            assert_equal 21, @new_spending_stat.total_received_from_councils # was nil
          end

          should "update payer_breakdown with financial_transaction organisation details" do
            @new_spending_stat.update_from(@receipt_1)
            assert_equal @expected_org_breakdown_1, @new_spending_stat.payer_breakdown
            
            @receipt_1.supplier.organisation = @another_org
            @new_spending_stat.update_from(@receipt_1)
            assert_equal @expected_org_breakdown_2, @new_spending_stat.payer_breakdown
          end
          
        end
      
      end
      
      # context "and financial_transaction date is month with existing value" do
      #   setup do
      #     @ft.date = '2009-09-10'
      #     @spending_stat.update_from(@ft)
      #   end
      # 
      #   should "add value to existing value" do
      #     expected_new_spend_by_month = [['2009-08-01'.to_date, 2519.0], ['2009-09-01'.to_date, 2519.0+321.4], ['2009-10-01'.to_date, nil], ['2009-11-01'.to_date, 5559.5]]
      #     assert_equal expected_new_spend_by_month, @spending_stat.spend_by_month
      #   end
      # end
      # 
      # context "and financial_transaction date is prior to existing months" do
      #   setup do
      #     @ft.date = '2009-06-10'
      #   end
      # 
      #   should "add financial_transaction value to spend_by_month, filling in gaps" do
      #     expected_new_spend_by_month = [['2009-06-01'.to_date, 321.4], ['2009-07-01'.to_date, nil]] + @spend_by_month
      #     @spending_stat.update_from(@ft)
      # 
      #     assert_equal expected_new_spend_by_month, @spending_stat.spend_by_month 
      #   end
      # end
      # 
      # context "and financial_transaction supplier has payee set" do
      #   setup do
      #     @supplier = @ft.supplier
      #     @supplier.payee = Factory(:police_authority)
      #     @new_ss = Factory(:spending_stat, :breakdown => {'Company' => 111.1}, 
      #                                       :total_spend => 111.1, 
      #                                       :earliest_transaction => 3.months.ago.to_date, 
      #                                       :latest_transaction => 1.month.ago.to_date, 
      #                                       :spend_by_month => [['2009-08-01'.to_date, 111.1]] )
      #   end
      # 
      #   should "update breakdown" do
      #     @new_ss.update_from(@ft)
      #     assert_equal( {'Company' => 111.1, 'PoliceAuthority' => 321.4}, @new_ss.breakdown)
      #     @new_ss.update_from(@ft)
      #     assert_equal( {'Company' => 111.1, 'PoliceAuthority' => 642.8}, @new_ss.breakdown)
      #   end
      # end
      # 
      # context "and just one existing month" do
      #   setup do
      #     @new_ss = Factory(:spending_stat)
      #     @new_ss.update_from(@ft)
      #   end
      # 
      #   should "update without exceptions" do
      #     assert_nothing_raised(Exception) { @new_ss.update_from(@ft) }
      #   end
      # end
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
        @council_with_zero_total_spend = Factory(:generic_council)
        Factory(:supplier, :organisation => @council_with_zero_total_spend, :payee => @company)
        @council_with_zero_total_spend.create_spending_stat.perform

        @breakdown = @bd_spending_stat.calculated_payer_breakdown
      end

      should "return an array of hashes" do
        assert_kind_of Array, @breakdown
        assert_kind_of Hash, @breakdown.first
      end
      
      should "return nil if spending_stat organisation doesn't have supplying_relationships" do
        assert_nil @second_supplier.create_spending_stat.calculated_payer_breakdown
      end
      
      should "cache result" do
        @company.expects(:supplying_relationships).never # already called once in setup
        @bd_spending_stat.calculated_payer_breakdown
      end
      
      should "have one hash per council" do
        assert_equal 20, @breakdown.size
      end
      
      context "and hash" do
        setup do
          @council_hash = @breakdown.detect{ |h| h[:organisation_id] == @first_council.id }
        end
        
        should "not include organisations with zero total spend" do
          assert !@breakdown.any?{ |h| h[:organisation_id] == @council_with_zero_total_spend.id }
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

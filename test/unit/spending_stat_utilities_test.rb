require 'test_helper'

class SpendingStatUtilitiesTest < ActiveSupport::TestCase
  
  context 'A class that mixes in SpendingStatUtilities::Base' do
    setup do
      @test_model_with_spending_stat = TestModelWithSpendingStat.create!
      @spending_stat = @test_model_with_spending_stat.create_spending_stat( :total_spend => 12345, 
                                                                            :average_monthly_spend => 420,
                                                                            :average_transaction_value => 34,
                                                                            :earliest_transaction => '2008-08-01',
                                                                            :latest_transaction => '2010-03-24')
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
    
    should "return nil for average_monthly_spend if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.average_monthly_spend
    end
    
    should "delegate average_transaction_value to spending_stat" do
      assert_equal @spending_stat.average_transaction_value, @test_model_with_spending_stat.average_transaction_value
    end
    
    should "return nil for average_transaction_value if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.average_transaction_value
    end
    
    should "delegate earliest_transaction to spending_stat" do
      assert_equal @spending_stat.earliest_transaction, @test_model_with_spending_stat.earliest_transaction
    end
    
    should "return nil for earliest_transaction if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.earliest_transaction
    end
    
    should "delegate latest_transaction to spending_stat" do
      assert_equal @spending_stat.latest_transaction, @test_model_with_spending_stat.latest_transaction
    end
    
    should "return nil for latest_transaction if no spending_stat" do
      assert_nil TestModelWithSpendingStat.new.latest_transaction
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
    
    context "when caching spending data" do
      setup do
        TestModelWithSpendingStat.stubs(:calculated_spending_data).returns({:total_spend => 1234, :transaction_count => 45})
        @cached_file_location = File.join(RAILS_ROOT, 'db', 'data', 'cache', 'test_model_with_spending_stat_spending')
        File.rename(@cached_file_location, @cached_file_location + '_original') if File.exist?(@cached_file_location)
      end
      
      teardown do
        File.rename(@cached_file_location + '_original', @cached_file_location) if File.exist?(@cached_file_location + '_original')
      end
      
      should "get calculated spending data" do
        TestModelWithSpendingStat.expects(:calculated_spending_data)
        TestModelWithSpendingStat.cache_spending_data
      end
      
      should "save calculated spending data as yaml in file" do
        TestModelWithSpendingStat.cache_spending_data
        YAML.load_file(@cached_file_location)
      end

      should "return file location" do
        assert_equal @cached_file_location, TestModelWithSpendingStat.cache_spending_data
      end
      
    end
    
    context "when returning cached_spending_data_location" do
      should "build from class_name" do
        assert_equal File.join(RAILS_ROOT, 'db', 'data', 'cache', "test_model_with_spending_stat_spending"), TestModelWithSpendingStat.cached_spending_data_location
      end
    end
    
    context "when returning cached_spending_data" do
      setup do
        @companies = 3.times.collect{ |i| c=Factory(:company); Factory(:spending_stat, :organisation => c, :total_received_from_councils => i*1000); c}
        @financial_transactions = 5.times.collect{|i| Factory(:financial_transaction, :value => i*500)}
        @charities = 1.times.collect{ |i| c=Factory(:charity); Factory(:spending_stat, :organisation => c, :total_received_from_councils => i*1000); c}
        @spending_data = { :supplier_count=>77665, 
                           :largest_transactions=>@financial_transactions.collect(&:id), 
                           :largest_companies=>@companies.collect(&:id), 
                           :total_spend=>3404705734.99173, 
                           :company_count=>27204, 
                           :largest_charities=>@charities.collect(&:id), 
                           :transaction_count=>476422}
        
        YAML.stubs(:load_file).returns(@spending_data)
      end
      
      should "check for council_spending in data cache store" do
        YAML.expects(:load_file).with(File.join(RAILS_ROOT, 'db', 'data', 'cache', 'test_model_with_spending_stat_spending'))
        TestModelWithSpendingStat.cached_spending_data
      end
      
      should "return nil if no cached file" do
        YAML.expects(:load_file) # returns nil
        assert_nil TestModelWithSpendingStat.cached_spending_data
      end
            
      context "and spending_data is in cache" do

        should "return spending_data hash" do
          assert_kind_of Hash, TestModelWithSpendingStat.cached_spending_data
        end
        
        context "and Hash" do
          setup do
            @cached_spending_data = TestModelWithSpendingStat.cached_spending_data
          end

          should "replace ids for largest items where name translates into class" do
            assert_equal @companies.size, @cached_spending_data[:largest_companies].size
            assert_kind_of Company, @cached_spending_data[:largest_companies].first
          end
          
          should "sort by order in cached_spending_data" do
            assert_equal @companies.first, @cached_spending_data[:largest_companies].first
          end
          
          should "not replace ids for largest items where name does not translate into class" do
            assert_equal @financial_transactions.first.id, @cached_spending_data[:largest_transactions].first
          end
          
        end
      end
      
      context "and problem parsing YAML" do
        setup do
          YAML.expects(:load_file).raises
        end

        should "return nil" do
          assert_nil Council.cached_spending_data
        end
        
        should_eventually "email admin" do
          
        end
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
    
    context "when supplying_relationship added" do
      setup do
        @payee = Factory(:entity)
        @supplier = Factory(:supplier)
      end

      should "update_spending_stat for self, organisation and supplying_relationship" do
        @supplier.expects(:update_spending_stat)
        @supplier.organisation.expects(:update_spending_stat)
        @payee.expects(:update_spending_stat)
        @payee.supplying_relationships << @supplier
      end
    end
    
    context "when supplying_relationship removed" do
      setup do
        @payee = Factory(:entity)
        @supplier = Factory(:supplier)
        @payee.supplying_relationships << @supplier
      end

      should "update_spending_stat for self, organisation and supplying_relationship" do
        @supplier.expects(:update_spending_stat)
        @supplier.organisation.expects(:update_spending_stat)
        @payee.expects(:update_spending_stat)
        @payee.supplying_relationships.delete(@supplier)
      end
      
    end    
      
    should 'have data_for_payer_breakdown instance method' do
      assert TestModelWithSpendingStatPayee.new.respond_to?(:data_for_payer_breakdown)
    end
      
    context "and data_for_payer_breakdown" do
      setup do
        @org_1 = Factory(:generic_council, :title  => "Z Council")
        @org_2 = Factory(:entity, :title  => "An entity")
        @supplying_relationship_1 = Factory(:supplier, :payee => @test_model_with_spending_stat_payee, :organisation => @org_1)
        @supplying_relationship_1a = Factory(:supplier, :payee => @test_model_with_spending_stat_payee, :organisation => @org_1)
        @supplying_relationship_1b = Factory(:supplier, :payee => @test_model_with_spending_stat_payee, :organisation => @org_1)
        @supplying_relationship_2 = Factory(:supplier, :payee => @test_model_with_spending_stat_payee, :organisation => @org_2)
      end

      should "return nil if no supplying_relationships" do
        assert_nil TestModelWithSpendingStatPayee.create.data_for_payer_breakdown
      end
      
      should "return array of arrays" do
        assert_kind_of Array, @test_model_with_spending_stat_payee.data_for_payer_breakdown
        assert_kind_of Array, @test_model_with_spending_stat_payee.data_for_payer_breakdown.first
      end
      
      should "have organisation as first element of arrays" do
        assert @test_model_with_spending_stat_payee.data_for_payer_breakdown.assoc(@org_1)
        assert @test_model_with_spending_stat_payee.data_for_payer_breakdown.assoc(@org_2)
      end
      
      should "return arrays in order of title of supplying_relationship organisation" do
        assert_equal @org_2, @test_model_with_spending_stat_payee.data_for_payer_breakdown.first.first
      end
      
      should "have hash as first second element of arrays" do
        assert_kind_of Hash, @test_model_with_spending_stat_payee.data_for_payer_breakdown.first[1]
      end
      
      context "and hash" do
        setup do
          @supplying_relationship_1.create_spending_stat(:total_spend => 123.4, :earliest_transaction => "2008-03-25", :latest_transaction => "2008-08-10")
          @supplying_relationship_1b.create_spending_stat(:total_spend => 234.5, :earliest_transaction => "2008-06-25", :latest_transaction => "2008-10-10")
          @subtotal_hash = @test_model_with_spending_stat_payee.data_for_payer_breakdown.assoc(@org_1)[1][:subtotal]
        end

        should "have supplying_relationships keyed to :elements" do
          srs = [@supplying_relationship_1, @supplying_relationship_1a, @supplying_relationship_1b]
          assert_equal srs, @test_model_with_spending_stat_payee.data_for_payer_breakdown.assoc(@org_1)[1][:elements]
        end
        
        should "have subtotal array keyed to :subtotal with organisation as first element" do
          assert_equal @org_1, @subtotal_hash.first
        end
        
        should "sum supplying_relationships total_spend as integers for second element of :elements" do
          assert_equal 123+234, @subtotal_hash[1]
        end
        
        should "average total_spend over number of months for third element of :elements" do
          assert_equal ((123+234)/8).to_i, @subtotal_hash[2]
        end
        
      end
    end
  end
  
end
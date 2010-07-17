require 'test_helper'

class FinancialTransactionTest < ActiveSupport::TestCase
  subject { @financial_transaction }
  
  context "The FinancialTransaction class" do
    setup do
      @financial_transaction = Factory(:financial_transaction)
    end
    
    # should validate_presence_of :supplier_id
    should validate_presence_of :value
    should validate_presence_of :date
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
    
    should 'validate presence of supplier_id' do
      # NB Shoulda macro not working for some reason
      f=Factory.build(:financial_transaction, :supplier_id => nil)
      assert !f.valid?
      assert f.errors[:supplier_id]
    end                        
    
    context "when saving" do
      setup do
        supplier = Factory.build(:supplier)
        @financial_transaction = Factory.build(:financial_transaction, :supplier => supplier)
      end
    
      should "save associated supplier" do
        @financial_transaction.save!
        assert !@financial_transaction.supplier.new_record?
      end
      
      context "and supplier isn't valid" do
        setup do
          supplier = Supplier.new
          @financial_transaction = Factory.build(:financial_transaction, :supplier => supplier)
        end
    
        should "not save financial_transaction" do
          assert !@financial_transaction.save
        end
      end
      
      should "update total_spend of associated supplier" do
        @supplier = @financial_transaction.supplier
        @another_financial_transaction = Factory(:financial_transaction, :description => 'foobar***', :supplier => @supplier, :value => 42)

        @financial_transaction.value = 31
        @financial_transaction.save!
        assert_equal 73, @supplier.reload.total_spend
      end
      
    end
  end
  
  context 'an instance of the FinancialTransaction class' do
    setup do
      @financial_transaction = Factory(:financial_transaction)
    end
    
    context 'when returning title' do
      should 'use date' do
        assert_equal "Transaction with #{@financial_transaction.supplier.title} on #{@financial_transaction.date.to_s(:event_date)}", @financial_transaction.title
      end
      
      should 'use date and uid when uid is set' do
        @financial_transaction.uid = '1234A'
        assert_equal "Transaction 1234A with #{@financial_transaction.supplier.title} on #{@financial_transaction.date.to_s(:event_date)}", @financial_transaction.title
      end
    end
        
    context "when setting value" do

      should "assign value as expected" do
        assert_equal 34567.23, Factory(:financial_transaction, :value => 34567.23).value
        assert_equal -34567.23, Factory(:financial_transaction, :value => -34567.23).value
      end

      should "strip out commas" do
        assert_equal 34567.23, Factory(:financial_transaction, :value => '34,567.23').value
        assert_equal 34567890.23, Factory(:financial_transaction, :value => '34,567,890.23').value
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
    
    context "when returning organisation" do

      should "return supplier organisation" do
        assert_equal @financial_transaction.supplier.organisation, @financial_transaction.organisation
      end
      
      should 'return @organisation instance variable if set' do
        dummy_org = stub
        fin_trans = FinancialTransaction.new
        fin_trans.instance_variable_set(:@organisation, dummy_org)
        assert_equal dummy_org, fin_trans.organisation
      end
      
      should 'return nil if @organisation instance variable not set' do
        assert_nil FinancialTransaction.new.organisation
      end
    end


   context 'when setting supplier_name' do
     setup do
       @existing_supplier = Factory(:supplier, :name => 'Foo Supplier')
       @organisation = @existing_supplier.organisation
     end
     
     context 'and organisation not set' do
       setup do
         @fin_trans = FinancialTransaction.new
       end
       
       should 'should not try to find supplier' do
         Supplier.expects(:find).never
         @fin_trans.supplier_name = 'Foo Supplier'
       end
       
       should "should instantiate new supplier if it doesn't exist" do
         @fin_trans.supplier_name = 'Bar Supplier'
	        assert_kind_of Supplier, supplier = @fin_trans.supplier
	        assert_equal 'Bar Supplier', supplier.name
	      end
	      
        should "should update existing supplier instance if already set" do
          @fin_trans.supplier_uid = 'ab123'
          @fin_trans.supplier_name = 'Bar Supplier'
 	        assert_kind_of Supplier, supplier = @fin_trans.supplier
 	        assert_equal 'Bar Supplier', supplier.name
 	        assert_equal 'ab123', supplier.uid
 	      end
	    end
	 
	    context 'and organisation set' do
	      setup do
	        @fin_trans = FinancialTransaction.new(:organisation => @organisation)
	      end
	      
	      should 'should find supplier for organisation if it exists' do
	        @fin_trans.supplier_name = 'Foo Supplier'
	        assert_equal @existing_supplier, @fin_trans.supplier
	      end
	      
	      should "should instantiate new supplier for organisation if it doesn't exist" do
	        @fin_trans.supplier_name = 'Bar Supplier'
	        assert_kind_of Supplier, supplier = @fin_trans.supplier
	        assert_equal 'Bar Supplier', supplier.name
	        assert_equal @organisation, supplier.organisation
	      end
	      
 	      should "update existing supplier for organisation if set" do
 	        @fin_trans.supplier_id = 'abc123'
 	        @fin_trans.supplier_name = 'Bar Supplier'
 	        assert_kind_of Supplier, supplier = @fin_trans.supplier
 	        assert_equal 'Bar Supplier', supplier.name
 	        assert_equal @organisation, supplier.organisation
 	      end
	    end
	  end
	 
    context 'when setting supplier_uid' do
      setup do
        @existing_supplier = Factory(:supplier, :name => 'Foo Supplier', :uid => "ab123")
        @organisation = @existing_supplier.organisation
      end

      context 'and organisation not set' do
        setup do
          @fin_trans = FinancialTransaction.new
        end

        should 'should not try to find supplier' do
          Supplier.expects(:find).never
          @fin_trans.supplier_name = 'Foo Supplier'
        end

        should "should instantiate new supplier with given if it doesn't exist" do
          @fin_trans.supplier_uid = 'ab123'
 	        assert_kind_of Supplier, supplier = @fin_trans.supplier
 	        assert_equal 'ab123', supplier.uid
 	      end
 	      
 	      should "update existing supplier instance if already set" do
 	        @fin_trans.supplier_name = 'Bar Supplier'
          @fin_trans.supplier_uid = 'ab123'
 	        assert_kind_of Supplier, supplier = @fin_trans.supplier
 	        assert_equal 'ab123', supplier.uid
 	        assert_equal 'Bar Supplier', supplier.name
 	      end
 	    end

 	    context 'and organisation set' do
 	      setup do
 	        @fin_trans = FinancialTransaction.new(:organisation => @organisation)
 	      end

 	      should 'find supplier for organisation if it exists' do
 	        @fin_trans.supplier_name = 'Foo Supplier'
 	        assert_equal @existing_supplier, @fin_trans.supplier
 	      end

 	      should "instantiate new supplier for organisation if it doesn't exist" do
 	        @fin_trans.supplier_name = 'Bar Supplier'
 	        assert_kind_of Supplier, supplier = @fin_trans.supplier
 	        assert_equal 'Bar Supplier', supplier.name
 	        assert_equal @organisation, supplier.organisation
 	      end
 	      
 	    end
 	  end

	  context 'when setting organisation' do
	    setup do
	      @organisation = Factory(:police_force)
	    end
	    
	    context 'and supplier not set' do
	      setup do
	        @fin_trans = FinancialTransaction.new
	      end
	      
	      should 'set instance variable' do
	        @fin_trans.organisation = @organisation
	        assert_equal @organisation, @fin_trans.instance_variable_get(:@organisation)
	      end
	      
	      should "should not do anything with supplier" do
	        @fin_trans.organisation = @organisation
	        assert_nil @fin_trans.supplier
	      end
	    end
	 
	    context 'and supplier is set' do
	      
	      should 'should assign organisation to supplier' do
	        @fin_trans = FinancialTransaction.new(:supplier_name => 'Bar Supplier')
	        @fin_trans.organisation = @organisation
	        assert_equal @organisation, @fin_trans.supplier.organisation
	      end
	      
	      should 'should try to match existing suppliers' do
	        exist_supplier = Factory(:supplier, :organisation => @organisation, :name => 'Bar Supplier')
	        @fin_trans = FinancialTransaction.new(:supplier_name => 'Bar Supplier')
	        @fin_trans.organisation = @organisation
	        assert_equal exist_supplier, @fin_trans.supplier
	      end
	      
	    end
	  end
    
    should 'be able to be created when supplied with necessary supplier params' do
      # This is sort of integration test for whole lifecycle of saving with supplier info, as happens when parsing csv files
      org = Factory(:police_force)
      ft = FinancialTransaction.new(:value => "32.40", :date => 2.days.ago, :supplier_name => 'Foo Inc', :organisation => org)
      assert ft.save
      assert ft.errors.empty?
      assert !ft.supplier.new_record?
    end
  end                      
end

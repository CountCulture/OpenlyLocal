require 'test_helper'

class SupplierTest < ActiveSupport::TestCase
  subject { @supplier }
  
  context "The Supplier class" do
    setup do
      @supplier = Factory(:supplier)
      @organisation = @supplier.organisation
      @spending_stat = @supplier.create_spending_stat(:total_spend => 543.2,
                                                      :average_monthly_spend => 32.1,
                                                      :average_transaction_value => 55.4)
    end
    
    should have_many(:financial_transactions).dependent(:destroy)
    should have_one(:spending_stat).dependent(:destroy)
    # should belong_to :company
    should validate_presence_of :organisation_type
    should validate_presence_of :organisation_id
    
    should have_db_column :uid
    should have_db_column :url
    should have_db_column :name
    should have_db_column :failed_payee_search
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:supplier, :organisation => organisation).organisation
    end
    
    should 'belong to payee polymorphically' do
      payee = Factory(:company)
      assert_equal payee, Factory(:supplier, :payee => payee).payee
    end
    
    context "should have unmatched named_scope which" do
      setup do
        @payee = Factory(:company)
        @supplier_with_payee = Factory(:supplier, :payee => @payee)
      end
      
      should 'include suppliers without payees' do
        assert Supplier.unmatched.include?(@supplier)
      end
      
      should 'not include suppliers with payees' do
        assert !Supplier.unmatched.include?(@supplier_with_payee)
      end
    end
    
    context "should have filter_by named_scope which" do
      setup do
        @payee = Factory(:company)
        @another_supplier = Factory(:supplier, :name => 'Another Supplier')
      end
      
      should 'return all suppliers by default' do
        assert Supplier.filter_by({}).include?(@supplier)
        assert Supplier.filter_by({}).include?(@another_supplier)
      end
      
      should 'return all suppliers when name is nil' do
        assert Supplier.filter_by({:name => nil}).include?(@supplier)
      end
      
      should 'return those with names like given name' do
        assert Supplier.filter_by(:name => 'anoth').include?(@another_supplier)
        assert !Supplier.filter_by(:name => 'anoth').include?(@supplier)
      end

      should 'return those with names like given name ignoring case' do
        assert Supplier.filter_by(:name => 'ANOTH').include?(@another_supplier)
      end

      should 'return those with names like given name position of match' do
        assert Supplier.filter_by(:name => 'nothe').include?(@another_supplier)
      end
    end
    
    should "delegate total_spend to spending_stat" do
      assert_equal @spending_stat.total_spend, @supplier.total_spend
    end
    
    should "return for total_spend if no spending_stat" do
      assert_nil Supplier.new.total_spend
    end
    
    should "delegate average_monthly_spend to spending_stat" do
      assert_equal @spending_stat.average_monthly_spend, @supplier.average_monthly_spend
    end
    
    should "return for average_monthly_spend if no spending_stat" do
      assert_nil Supplier.new.average_monthly_spend
    end
    
    should "delegate average_transaction_value to spending_stat" do
      assert_equal @spending_stat.average_transaction_value, @supplier.average_transaction_value
    end
    
    should "return for average_transaction_value if no spending_stat" do
      assert_nil Supplier.new.average_transaction_value
    end
    
    should 'require either name or uid to be present' do
      invalid_supplier = Factory.build(:supplier, :name => nil, :uid => nil)
      assert !invalid_supplier.valid?
      assert_equal 'Either a name or uid is required', invalid_supplier.errors[:base]
      invalid_supplier.name = 'foo'
      assert invalid_supplier.valid?
      invalid_supplier.name = nil
      invalid_supplier.uid = '123'
      assert invalid_supplier.valid?
    end
    
    context 'when validating uniqueness of uid' do
      
      should 'scope to organisation' do
        @supplier.update_attribute(:uid, '123')
        another_supplier = Factory.build(:supplier, :uid => '123') # different org
        assert another_supplier.valid?
        another_supplier.organisation = @organisation
        assert !another_supplier.valid?
      end
      
      should 'allow nil' do
        another_supplier = Factory.build(:supplier, :organisation => @organisation)
        assert another_supplier.valid?
      end
    end
    
    context "when normalising title" do
      should "normalise title" do
        TitleNormaliser.expects(:normalise_company_title).with('foo bar')
        Supplier.normalise_title('foo bar')
      end
    end
    
    context "when finding_from_params" do
      setup do
        @existing_supplier = Factory(:supplier, :name => 'Foo Company')
        @organisation = @existing_supplier.organisation
        @another_org_supplier = Factory(:supplier, :name => 'Bar Company')
        @another_org = @another_org_supplier.organisation
        @existing_supplier_with_uid = Factory(:supplier, :name => 'Bar Company', :uid => 'ab123', :organisation => @organisation)
        @another_org_supplier_with_uid_and_no_name = Factory(:supplier, :name => nil, :uid => 'bc456', :organisation => @another_org)
      end
      
      should "return supplier with given name found for organisation" do
        assert_equal @existing_supplier, Supplier.find_from_params(:organisation => @organisation, :name => 'Foo Company')
      end
      
      should "return supplier with given uid ignoring title if uid given" do
        assert_equal @existing_supplier_with_uid, Supplier.find_from_params(:organisation => @organisation, :uid => 'ab123', :name => 'Foo Company')
      end

      should "raise exception if no organisation" do
        assert_raise(NoMethodError) { Supplier.find_from_params(:name => 'Foo Company') }
      end
      
      should "return nil if no supplier with given name found for organisation" do
        assert_nil Supplier.find_from_params(:organisation => @another_org, :name => 'Foo Company')
      end
      
      should "not search using uid if uid blank" do
        assert_nil Supplier.find_from_params(:organisation => @another_org, :name => 'Foo Company', :uid => '')
        assert_nil Supplier.find_from_params(:organisation => @another_org, :name => 'Foo Company', :uid => nil)
        assert_nil Supplier.find_from_params(:organisation => @another_org, :name => nil, :uid => nil)
      end
      
      should "search using name if uid blank" do
        assert_equal @existing_supplier, Supplier.find_from_params(:organisation => @organisation, :name => 'Foo Company', :uid => '')
        assert_equal @existing_supplier, Supplier.find_from_params(:organisation => @organisation, :name => 'Foo Company', :uid => nil)
      end
      
      should "not search using name if name blank" do
        assert_nil Supplier.find_from_params(:organisation => @another_org, :name => '', :uid => 'ab123')
        assert_nil Supplier.find_from_params(:organisation => @another_org, :name => nil, :uid => 'ab123')
      end
      
      should "search using uid if name blank" do
        assert_equal @another_org_supplier_with_uid_and_no_name, Supplier.find_from_params(:organisation => @another_org, :name => '', :uid => 'bc456')
        assert_equal @another_org_supplier_with_uid_and_no_name, Supplier.find_from_params(:organisation => @another_org, :name => nil, :uid => 'bc456')
      end
    end
  end
  
  context "An instance of the Supplier class" do
    setup do
      @supplier = Factory(:supplier)
    end

    should "alias name as title" do
      assert_equal @supplier.name, @supplier.title
    end
    
    should "use title when converting to_param" do
      @supplier.title = "some title-with/stuff"
      assert_equal "#{@supplier.id}-some-title-with-stuff", @supplier.to_param
    end

    context 'when saving' do
      
      context "and no associated spending stat" do
        setup do
          @supplier.spending_stat.destroy
          @supplier.reload
        end
        
        should "create spending stat" do
          assert_difference "SpendingStat.count", 1 do
            @supplier.save
          end
          assert @supplier.spending_stat
          assert !@supplier.spending_stat.new_record?
        end
        
        should "queue created spending stat for updating" do
          Delayed::Job.expects(:enqueue).with(kind_of(SpendingStat))
          @supplier.save
        end
      end
      
      context "and associated spending_stat exists" do
        # @supplier already has one
        should "not create new spending_stat" do
          assert_no_difference "SpendingStat.count" do
            @supplier.save
          end
        end
        should "queue created spending stat for updating" do
          Delayed::Job.expects(:enqueue).with(kind_of(SpendingStat))
          @supplier.save
        end
      end
    end
    
    context 'after creating' do
      setup do
        @company = Factory(:company)
      end
      
      should 'try to match against company if company' do
        Supplier.any_instance.expects(:possible_payee)
        Factory(:supplier, :name => 'Foo company')
      end
      
      should 'and should associate with returned body' do
        Supplier.any_instance.expects(:possible_payee).returns(@company)
        supplier = Factory(:supplier, :name => 'Foo company')
        assert_equal @company, supplier.reload.payee
      end
      
    end
    
    context "when matching against existing possible payees" do
      context "and name is company-like" do
        setup do
          @supplier.name = 'Foo Ltd'
        end

        should "try to match against company" do
          Company.expects(:matches_title).with('Foo Ltd')
          @supplier.possible_payee
        end
      end
      
      context "and name is police authority like" do
        setup do
          @supplier.name = 'Foo Police Authority'
        end

        should "try to match against police authority" do
          PoliceAuthority.expects(:find_by_name).with('Foo Police Authority')
          @supplier.possible_payee
        end
      end
      
      context "and name is council-like" do
        setup do
          @supplier.name = 'Foo Council'
        end

        should "try to match against council" do
          Council.expects(:find_by_normalised_title).with('foo')
          @supplier.possible_payee
        end
        
        should "ignore case" do
          @supplier.name = 'FOO COUNCIL'
          Council.expects(:find_by_normalised_title).with('foo')
          @supplier.possible_payee
        end
        
      end
    end
    
    context "when finding and associating new company" do
      setup do
      end
      
      should 'search using CompaniesUtilities and supplier name' do
        CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with(@supplier.name)
        @supplier.find_and_associate_new_company
      end
      
      context "and single company is returned" do
        setup do
          company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}]
          CompanyUtilities::Client.any_instance.stubs(:find_company_from_name).returns(company_response)
        end
      
        should "create company" do
          assert_difference "Company.count", 1 do
            @supplier.find_and_associate_new_company
          end
        end
        
        should "associate company with supplier" do
          @supplier.find_and_associate_new_company
          assert company = @supplier.reload.payee
          assert_equal "SPIKES CAVELL & COMPANY LIMITED", company.title
          assert_equal "06398324", company.company_number
        end
      end
      
      context "and no company is returned" do
        setup do
          CompanyUtilities::Client.any_instance.stubs(:find_company_from_name) # => returns nil still
        end
      
        should "not create company" do
          assert_no_difference "Company.count" do
            @supplier.find_and_associate_new_company
          end
        end
        
        should "not associate company with supplier" do
          @supplier.find_and_associate_new_company
          assert_nil @supplier.reload.payee
        end
        
        should "mark supplier as failed_payee_search" do
          CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil still
          @supplier.find_and_associate_new_company
          assert @supplier.reload.failed_payee_search?
        end
        
        context "and supplier name has ampersand in it" do
          setup do
            @supplier.update_attribute(:title, 'Spikes Cavell & Company Ltd')
            @company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL AND COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}]             
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil
          end

          should "make second call replacing ampersand with 'and'" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with('Spikes Cavell and Company Ltd').returns(@company_response) # then returns company response
            @supplier.find_and_associate_new_company
          end

          should "create company from info returned in second call" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with('Spikes Cavell and Company Ltd').returns(@company_response) # then returns company response
            assert_difference "Company.count", 1 do
              @supplier.find_and_associate_new_company
            end
          end

          should "associate company with supplier" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with('Spikes Cavell and Company Ltd').returns(@company_response) # then returns company response
            @supplier.find_and_associate_new_company
            assert company = @supplier.reload.payee
            assert_equal "SPIKES CAVELL AND COMPANY LIMITED", company.title
            assert_equal "06398324", company.company_number
          end
          
          should "not create company if still no company" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil still
            assert_no_difference "Company.count" do
              @supplier.find_and_associate_new_company
            end
          end
          
          should "mark supplier as failed_payee_search" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil still
            @supplier.find_and_associate_new_company
            assert @supplier.reload.failed_payee_search?
          end
          
        end
      end
      
      context "and several companies are returned" do
        setup do
          @supplier.update_attribute(:title, 'Spikes Cavell Analytic Ltd')
          company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}, {:status=>"Active", :company_number=>"04917291", :title=>"SPIKES CAVELL ANALYTIC LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2003-10-01"}]
          CompanyUtilities::Client.any_instance.stubs(:find_company_from_name).returns(company_response)
        end
      
        should "create company" do
          assert_difference "Company.count", 1 do
            @supplier.find_and_associate_new_company
          end
        end
        
        should "match company with matching normalised title" do
          @supplier.find_and_associate_new_company
          assert Company.find_by_company_number('04917291')
          assert !Company.find_by_company_number('06398324')
        end
        
      
        should "associate company with supplier" do
          @supplier.find_and_associate_new_company
          assert company = @supplier.reload.payee
          assert_equal "SPIKES CAVELL ANALYTIC LIMITED", company.title
          assert_equal "04917291", company.company_number
        end
        
        context "and no matching normalised title" do
          setup do
            @supplier.update_attribute(:title, 'Spikes Cavell Analytic')
          end
          
          should "not create company" do
            assert_no_difference "Company.count" do
              @supplier.find_and_associate_new_company
            end
          end
          
          should "not associate company with supplier" do
            @supplier.find_and_associate_new_company
            assert_nil @supplier.payee
          end
        end
      end
      
    end
    
    context 'when assigning company_number' do
      setup do
        @company = Factory(:company)
      end
      
      should 'match or create company from company number' do
        Company.expects(:match_or_create_from_company_number).with('123456')
        @supplier.company_number = '123456'
      end
      
      should 'associate returned company with given company number' do
        Company.stubs(:match_or_create_from_company_number).returns(@company)
        @supplier.company_number = '123456'
        assert_equal @company, @supplier.reload.payee
      end
      
      # context "and company with given number already exists" do
      #   setup do
      #     @old_company_count = Company.count
      #     @supplier.company_number = @existing_company.company_number
      #   end
      #   
      #   should 'not create new company' do
      #     assert_equal @old_company_count, Company.count
      #   end
      #   
      #   
      # end
      # 
      # context "and company not found" do
      #   
      #   should "create new company with given id" do
      #     assert_difference "Company.count", 1 do
      #        @supplier.company_number = '012345'
      #     end
      #     assert_equal '012345', @supplier.payee.company_number
      #   end
      # end
      
    end
        
    context "when returning associateds" do
      setup do
        @payee = Factory(:company)
        @supplier.update_attribute(:payee, @payee)
        @sibling_supplier = Factory(:supplier, :payee => @payee)
        @sole_supplier = Factory(:supplier, :payee => Factory(:company))
      end

      should "return suppliers belong to same company" do
        assert_equal [@sibling_supplier], @supplier.associateds
      end
      
      should "return empty array if no company for supplier" do
        assert_equal [], Factory(:supplier).associateds
      end
      
      should "return empty array if no other suppliers for company" do
        assert_equal [], @sole_supplier.associateds
      end
      
    end
    
    context 'and when updating supplier details' do
      
      setup do
        @new_details = SupplierDetails.new(:url => 'http://foo.com', :company_number => '01234', :wikipedia_url => 'http://en.wikipedia.org/wiki/foo')
      end
      
      context "in general" do

        should "create new company" do
          assert_difference "Company.count", 1 do
            @supplier.update_supplier_details(@new_details)
          end
        end
        
        should "associate new company with supplier" do
          @supplier.update_supplier_details(@new_details)
          assert_kind_of Company, c = @supplier.reload.payee
          assert_equal "00001234", c.company_number
        end
        
        should "assign url and wikipedia_url to new company" do
          @supplier.update_supplier_details(@new_details)
          assert_equal 'http://foo.com', @supplier.payee.url
          assert_equal 'http://en.wikipedia.org/wiki/foo', @supplier.payee.wikipedia_url
        end
        
        should "return true" do
          assert @supplier.update_supplier_details(@new_details)
        end
        
      end
      
      
      context "when company with given company number already exists" do
        setup do
          @existing_company = Factory(:company, :company_number => '00001234')
        end

        should "not create new company" do
          assert_no_difference "Company.count" do
            @supplier.update_supplier_details(@new_details)
          end
        end

        should "associate existing company with supplier" do
          @supplier.update_supplier_details(@new_details)
          assert_equal @existing_company, @supplier.reload.payee
        end
        
        # should "assign url and wikipedia_url to new company" do
        #   @supplier.update_supplier_details(@new_details)
        #   assert_equal 'http://foo.com', @existing_company.url
        #   assert_equal 'http://en.wikipedia.org/wiki/foo', @existing_company.wikipedia_url
        # end
        
        should "return true" do
          assert @supplier.update_supplier_details(@new_details)
        end
      end
      
      context 'when missing essential data' do
        should 'return false' do
          assert !@supplier.update_supplier_details(SupplierDetails.new(:company_number => ''))
        end
      end
      # should 'set website if not set' do
      #   @supplier.update_supplier_details(@new_details)
      #   assert_equal 'http://foo.com', @supplier.reload.url
      # end
      # 
      # should 'update website if set' do
      #   @supplier.update_attribute(:url, 'htp://bar.com')
      #   @supplier.update_supplier_details(@new_details)
      #   assert_equal 'http://foo.com', @supplier.reload.url
      # end
      # 
      should 'assign company with (normalised version of) given company number' do
        @supplier.update_supplier_details(@new_details)
        assert_equal '00001234', @supplier.reload.payee.company_number
      end
      
      should 'not delete existing url if nil given for url' do
        @supplier.update_attribute(:url, 'http://bar.com')
        @supplier.update_supplier_details(SupplierDetails.new(:url => nil))
        assert_equal 'http://bar.com', @supplier.reload.url
      end
      
      should 'not delete existing company if nil given for company_number' do
        @company = Factory(:company)
        @supplier.update_attribute(:payee, @company)
        @supplier.update_supplier_details(SupplierDetails.new(:company_number => nil))
        assert_equal @company, @supplier.reload.payee
      end
      
    end

  end
end

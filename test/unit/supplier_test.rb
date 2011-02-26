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
    
    should "have vat_number accessor" do
      assert @supplier.respond_to?(:vat_number)
      assert @supplier.respond_to?(:vat_number=)
    end
    
    should "have company_number accessor" do
      assert @supplier.respond_to?(:company_number)
      # assert @supplier.respond_to?(:vat_number=)
    end
    
    should 'mixin SpendingStatUtilities::Base' do
      assert @supplier.respond_to?(:spending_stat)
    end
    
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
    
    should "show extract class names from AllowedPayeeModels as allowed_payee_classes method" do
      assert_equal Supplier::AllowedPayeeModels.collect(&:first), Supplier.allowed_payee_classes
    end
    
    should "alias financial_transactions as payments" do
      Factory(:financial_transaction, :supplier => @supplier)
      Factory(:financial_transaction, :supplier => @supplier)
      assert_equal @supplier.financial_transactions, @supplier.payments
    end
  end
  
  context "An instance of the Supplier class" do
    setup do
      @supplier = Factory(:supplier)
    end

    should "alias name as title" do
      assert_equal @supplier.name, @supplier.title
    end
    
    should 'return correct url as openlylocal_url' do
      assert_equal "http://#{DefaultDomain}/suppliers/#{@supplier.to_param}", @supplier.openlylocal_url
    end
     
    should "use title when converting to_param" do
      @supplier.title = "some title-with/stuff"
      assert_equal "#{@supplier.id}-some-title-with-stuff", @supplier.to_param
    end
    
    should "use id when converting to_param and no title" do
      @supplier[:name] = nil
      assert_equal "#{@supplier.id}-", @supplier.to_param
    end
    
    context "when assigning name" do

      should "remove excess spaces" do
        assert_equal 'Foo Bar Supplier', Supplier.new(:name => "   Foo#{160.chr}Bar Supplier\n  ").name
      end
      
      should "not fail when name is nil" do
        assert_nothing_raised(Exception) { Supplier.new(:name => nil) }
      end
    end

    context "when matching with payee" do
      setup do
        @dummy_payee = Factory(:company)
      end
      
      should "try to match against possible payee" do
        @supplier.expects(:possible_payee)
        @supplier.match_with_payee
      end
      
      should "update payee with possible payee" do
        @supplier.stubs(:possible_payee).returns(@dummy_payee)
        @supplier.match_with_payee
        assert_equal @dummy_payee, @supplier.payee
      end
      
      should "not flag supplier as failed_payee_search if payee returned" do
        @supplier.stubs(:possible_payee).returns(@dummy_payee)
        @supplier.match_with_payee
        assert !@supplier.failed_payee_search
      end
      
      should "flag supplier as failed_payee_search if no payee returned" do
        @supplier.stubs(:possible_payee) # returns nil
        @supplier.match_with_payee
        assert @supplier.failed_payee_search
      end
      
      should "update payee spending stat" do
        @supplier.stubs(:possible_payee).returns(@dummy_payee)
        @dummy_payee.expects(:update_spending_stat)
        @supplier.match_with_payee
      end
      
      should "update supplier spending stat" do
        @supplier.stubs(:possible_payee).returns(@dummy_payee)
        @supplier.expects(:update_spending_stat)
        @supplier.match_with_payee
      end
      
      should "update supplier organisation spending stat" do
        @supplier.stubs(:possible_payee).returns(@dummy_payee)
        @supplier.organisation.expects(:update_spending_stat)
        @supplier.match_with_payee
      end
    end

    context "when updating payee" do
      setup do
        @dummy_payee = Factory(:company)
        @new_payee = Factory(:entity)
        @supplier.update_attribute(:payee, @dummy_payee)
      end
      
      should "update payee with new payee" do
        @supplier.update_payee(@new_payee)
        assert_equal @new_payee, @supplier.reload.payee
      end
      
      should "update new payee spending stat" do
        @new_payee.expects(:update_spending_stat)
        @supplier.update_payee(@new_payee)
      end
      
      should "update old payee spending stat" do
        @dummy_payee.expects(:update_spending_stat)
        @supplier.update_payee(@new_payee)
      end
      
      should "update supplier spending stat" do
        @supplier.expects(:update_spending_stat)
        @supplier.update_payee(@new_payee)
      end
      
      should "update supplier organisation spending stat" do
        @supplier.organisation.expects(:update_spending_stat)
        @supplier.update_payee(@new_payee)
      end
      
      context "and there is no existing payee" do
        should "not raise exception" do
          assert_nothing_raised(Exception) { Factory(:supplier).update_payee(Factory(:company)) }
        end
      end
    end

    context "when matching against existing possible payees" do
      context "and name is company-like" do
        setup do
          @supplier.name = 'Foo Ltd'
          # Company.stubs(:probable_company?).returns(true)
        end

        should "try to match against company" do
          Company.expects(:from_title).with('Foo Ltd')
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
      
      context "and name is pension fund-like" do
        setup do
          @supplier.name = 'Foo Pension Fund'
        end

        should "try to match against pension fund" do
          PensionFund.expects(:find_by_name).with('Foo Pension Fund')
          @supplier.possible_payee
        end
      end
      
      context "and name is town council-like" do
        setup do
          @supplier.name = 'Foo Town Council'
          @parish_council = Factory(:parish_council)
        end

        should "try to match all parish_councils matching normalised name" do
          ParishCouncil.expects(:find_all_by_normalised_title).with('foo')
          @supplier.possible_payee
        end
        
        should "return council if just one returned" do
          ParishCouncil.stubs(:find_all_by_normalised_title).returns([@parish_council])
          assert_equal @parish_council, @supplier.possible_payee
        end
        
        should "return nil if more than one returned" do
          ParishCouncil.stubs(:find_all_by_normalised_title).returns([@parish_council, @parish_council])
          assert_nil @supplier.possible_payee
        end
        
        should "return nil if none returned" do
          ParishCouncil.stubs(:find_all_by_normalised_title)
          assert_nil @supplier.possible_payee
        end
      end
      
      context "and name is parish council-like" do
        setup do
          @supplier.name = 'Bar Parish Council'
          @parish_council = Factory(:parish_council)
        end

        should "try to match all parish_councils matching normalised name" do
          ParishCouncil.expects(:find_all_by_normalised_title).with('bar')
          @supplier.possible_payee
        end
        
        should "return council if just one returned" do
          ParishCouncil.stubs(:find_all_by_normalised_title).returns([@parish_council])
          assert_equal @parish_council, @supplier.possible_payee
        end
        
        should "return nil if more than one returned" do
          ParishCouncil.stubs(:find_all_by_normalised_title).returns([@parish_council, @parish_council])
          assert_nil @supplier.possible_payee
        end
        
        should "return nil if none returned" do
          ParishCouncil.stubs(:find_all_by_normalised_title)
          assert_nil @supplier.possible_payee
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
      
      should "try to match against charities" do
        Charity.expects(:find_by_normalised_title).with(@supplier.name)
        @supplier.possible_payee
      end
      
      should "try to match against entities" do
        Entity.expects(:find_by_title).with(@supplier.name)
        @supplier.possible_payee
      end
    end
        
    context 'when assigning company_number' do
      setup do
        @company = Factory(:company, :company_number => 'AB123456')
        @another_company = Factory(:company, :company_number => 'CD456')
      end
      
      should 'associate company matching company number as payee' do
        @supplier.company_number = 'AB123456'
        assert_equal @company, @supplier.payee
      end
      
      should 'not change title of company matching company number' do
        title = @company.title
        @supplier.company_number = 'AB123456'
        assert_equal title, @supplier.payee.reload.title
      end
            
      context "and supplier already has associated company" do
        setup do
          @supplier.update_attribute(:payee, @company)
        end

        # should 'not match or create company from company number' do
        #   Company.expects(:match_or_create).never
        #   @supplier.company_number = 'AB123456'
        # end
        
        should "not update company with new company number" do
          company_number = @company.company_number
          @supplier.company_number = 'DE987'
          assert_equal company_number, @company.reload.company_number 
        end
        
        should "match existing company and associate as payeee" do
          @supplier.company_number = 'CD456'
          assert_equal @another_company, @supplier.payee
        end
      end
      
      context "and no company with company number exists" do

        should "associate with new company with company_number as payee" do
          @supplier.company_number = 'EF987'
          assert_kind_of Company, @supplier.payee
          assert_equal 'EF987', @supplier.payee.company_number
        end
        
        should "not save new company" do
          @supplier.company_number = 'EF987'
          assert @supplier.payee.new_record?
        end
      end
    end
        
    context 'when assigning vat_number' do
      setup do
        @company = Factory(:company, :vat_number => '123456', :company_number => nil)
      end
      
      should 'assign to vat_number instance_variable' do
        @supplier.vat_number = 'AB123456'
        assert_equal 'AB123456', @supplier.instance_variable_get(:@vat_number)
      end
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
      
      context "in general" do
        setup do
          @entity = Factory(:entity)
          @entity_details = SupplierDetails.new( :entity_type => 'Entity', 
                                                 :entity_id => @entity.id)
        end

        should "associate object described by entity_id and entity_type with supplier as payee" do
          @supplier.update_supplier_details(@entity_details)
          assert_equal @entity, @supplier.reload.payee
        end

        should "not associate entity with supplier as payee when entity type can't be a payee" do
          non_entity = Factory(:financial_transaction)
          non_entity_details = SupplierDetails.new( :entity_type => 'FinancialTransaction', 
                                                    :entity_id => non_entity.id)
          @supplier.update_supplier_details(non_entity_details)
          assert_nil @supplier.reload.payee
        end

        should "return true" do
          assert @supplier.update_supplier_details(@entity_details)
        end
        
        context "and url supplied in params" do
          setup do
            @entity = Factory(:entity)
            @entity_details = SupplierDetails.new( :entity_type => 'Entity', 
                                                   :entity_id => @entity.id,
                                                   :url => 'http://foo.com')
          end

          should "update payee url" do
            @supplier.update_supplier_details(@entity_details)
            assert_equal 'http://foo.com', @entity.reload.url
          end

          should "not update payee url if already set" do
            @entity.update_attribute(:url, 'http://bar.com')
            @supplier.update_supplier_details(@entity_details)
            assert_equal 'http://bar.com', @entity.reload.url
          end
        end
      end

      context "and company information supplied" do
        setup do
          @new_details = SupplierDetails.new( :url => 'http://foo.com', 
                                              :company_number => '01234',
                                              :entity_type => 'Company',
                                              :wikipedia_url => 'http://en.wikipedia.org/wiki/foo', 
                                              :source_for_info => 'http://foo.com/about_us')
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

          should "assign supplier title to new company" do
            @supplier.update_supplier_details(@new_details)
            assert_equal @supplier.title, @supplier.payee.title
          end

          should "update supplier spending_stat" do
            @supplier.expects(:update_spending_stat)
            @supplier.update_supplier_details(@new_details)
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
            assert !@supplier.update_supplier_details(SupplierDetails.new(:entity_type => 'Company', :company_number => ''))
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
      
      context "and charity information supplied" do
        setup do
          @matching_charity = Factory(:charity)
          @new_details = SupplierDetails.new( :charity_number => @matching_charity.charity_number,
                                              :entity_type => 'Charity',
                                              :source_for_info => 'http://foo.com/about_us')
        end

        should "associate matching charity with supplier as payee" do
          @supplier.update_supplier_details(@new_details)
          assert_equal @matching_charity, @supplier.reload.payee
        end

      end
    end

  end
end

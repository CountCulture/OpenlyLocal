require File.expand_path('../../test_helper', __FILE__)

class SupplierUtilitiesTest < ActiveSupport::TestCase

  context "A VatMatcher instance" do
    setup do
      @supplier = Factory(:supplier)
      @matcher = SupplierUtilities::VatMatcher.new(:vat_number => "FOO1234", :title => "Foo Org", :supplier => @supplier)
    end

    should "store vat_number as accessor" do
      assert_equal "FOO1234", @matcher.vat_number
    end
    
    should "remove GB from vat_number" do
      
      assert_equal "OO1234", SupplierUtilities::VatMatcher.new(:vat_number => "GBOO1234", :title => "Foo Org", :supplier => @supplier).vat_number
    end
    
    should "store title as accessor" do
      assert_equal "Foo Org", @matcher.title
    end
    
    should "store submitted supplier_id as instance_variable" do
      assert_equal @supplier.id, @matcher.instance_variable_get(:@supplier_id)
    end
    
    should "return supplier indentified with supplier id as supplier" do
      assert_equal @supplier, @matcher.supplier
    end
        
    context "when finding entity for matcher" do
      setup do
        @company = Factory(:company, :vat_number => "CO1", :title => "FOO & BAR LTD")
        @another_company = Factory(:company, :vat_number => "CO2", :title => "FOOBAR PLC")
        @company_owned_by_charity = Factory(:company, :vat_number => "CH1", :title => "Foo Concern Ltd")
        @charity = Factory(:charity, :vat_number => "CH1", :title => "Foo Concern")
        @council = Factory(:council, :vat_number => "CL1", :title => "London Borough of Foo")
        @entity = Factory(:entity, :vat_number => "QA1", :title => "Foo Body")
      end

      should "return entity matching Vat Number and title" do
        assert_equal @charity, SupplierUtilities::VatMatcher.new(:vat_number => "CH1", :title => "Foo Concern", :supplier => @supplier).find_entity
        assert_equal @entity, SupplierUtilities::VatMatcher.new(:vat_number => "QA1", :title => "Foo Body", :supplier => @supplier).find_entity
      end
      
      should "return entity matching Vat Number and normalised title if model supports it" do
        assert_equal @company, SupplierUtilities::VatMatcher.new(:vat_number => "CO1", :title => "Foo and Bar Limited", :supplier => @supplier).find_entity
      end
      
      should "return nil if no entity matching Vat Number and title" do
        assert_nil SupplierUtilities::VatMatcher.new(:vat_number => "CH1", :title => "Bar Concern", :supplier => @supplier).find_entity
        assert_nil SupplierUtilities::VatMatcher.new(:vat_number => "CH123", :title => "Foo Concern", :supplier => @supplier).find_entity
      end
            
    end

    context "when matching using external data" do

      context "and title is probable company" do
        setup do
          CompanyUtilities::Client.any_instance.stubs(:find_company_by_name).returns(:company_number => 'AB1234', :title => 'FOO LIMITED')
          @co_matcher = SupplierUtilities::VatMatcher.new(:vat_number => "FOO1234", :title => "Foo Ltd", :supplier => @supplier)
        end

        should "search companies house for company matching title" do
          CompanyUtilities::Client.any_instance.expects(:find_company_by_name).with("Foo Ltd")
          @co_matcher.match_using_external_data
        end
        
        should "create or match company using info returned from Companies House and VAT number" do
          Company.expects(:match_or_create).with(:company_number => 'AB1234', :title => 'FOO LIMITED', :vat_number => "FOO1234")
          @co_matcher.match_using_external_data
        end
        
        should "associate returned company with supplier" do
          company = Factory(:company)
          Company.stubs(:match_or_create).returns(company)
          @co_matcher.match_using_external_data
          assert_equal company, @supplier.reload.payee
        end
        
        should "send admin message if no company info returned from Companies House" do
          CompanyUtilities::Client.any_instance.expects(:find_company_by_name)
          AdminMailer.expects(:deliver_admin_alert!)
          @co_matcher.match_using_external_data
        end
        
      end 
      
      context "and title is not probable company" do
        setup do
          CompanyUtilities::Client.new.stubs(:find_company_by_name)
        end

        should "not search companies house for company matching title" do
          CompanyUtilities::Client.any_instance.expects(:find_company_by_name).never
          @matcher.match_using_external_data
        end
        
        should "get info re VAT number from EU VAT service" do
          CompanyUtilities::Client.any_instance.expects(:get_vat_info).with("FOO1234")
          @matcher.match_using_external_data
        end
        
        context "and if title returned by EU VAT service is probable company" do
          setup do
            CompanyUtilities::Client.any_instance.stubs(:get_vat_info).returns({:title => 'Foo Company Ltd', :address => '1 Foo St, London, SW1W 1AB'})
          end

          should "search companies house for company matching title returned by EU VAT service" do
            CompanyUtilities::Client.any_instance.expects(:find_company_by_name).with('Foo Company Ltd')
            @matcher.match_using_external_data
          end

          should "create or match company using info returned from Companies House and VAT number" do
            CompanyUtilities::Client.any_instance.stubs(:find_company_by_name).returns(:company_number => 'AB1234', :title => 'FOO LIMITED')
            Company.expects(:match_or_create).with(:company_number => 'AB1234', :title => 'FOO LIMITED', :vat_number => "FOO1234")
            @matcher.match_using_external_data
          end
          
          should "associate returned company with supplier" do
            company = Factory(:company)
            CompanyUtilities::Client.any_instance.stubs(:find_company_by_name).returns(:company_number => 'AB1234', :title => 'FOO LIMITED')
            Company.stubs(:match_or_create).returns(company)
            @matcher.match_using_external_data
            assert_equal company, @supplier.reload.payee
          end
          
          should "send admin message if no company info returned from Companies House" do
            CompanyUtilities::Client.any_instance.expects(:find_company_by_name)
            AdminMailer.expects(:deliver_admin_alert!)
            @matcher.match_using_external_data
          end

        end
        
        context "and if title returned by EU VAT service is not probable company" do
          setup do
            CompanyUtilities::Client.any_instance.stubs(:get_vat_info).returns({:title => 'Foo Society', :address => '1 Foo St, London, SW1W 1AB'})
          end

          should "not search companies house for company matching title returned by EU VAT service" do
            CompanyUtilities::Client.any_instance.expects(:find_company_by_name).never
            @matcher.match_using_external_data
          end

          should "find_entity for title and vat_number" do
            CompanyUtilities::Client.any_instance.expects(:find_company_by_name).never
            @matcher.expects(:find_entity)
            @matcher.match_using_external_data
          end
        end
        
      end 

    end

    context "when performing" do
      setup do
        @entity = Factory(:company)
      end

      should "find entity" do
        @matcher.expects(:find_entity).returns(@entity)
        @matcher.perform
      end
      
      should "associate found entity with supplier" do
        @matcher.stubs(:find_entity).returns(@entity)
        @matcher.perform
        assert_equal @entity, @supplier.reload.payee
      end
      
      should "not match using external data if entity found" do
        @matcher.stubs(:find_entity).returns(@entity)
        @matcher.expects(:match_using_external_data).never
        @matcher.perform
      end
      
      should "match using external data if no entity found" do
        @matcher.stubs(:find_entity)
        @matcher.expects(:match_using_external_data)
        @matcher.perform
      end

      context "and supplier already has payee" do
        setup do
          @company = Factory(:company, :vat_number => "CO1", :title => "FOO & BAR LTD")
          @company_without_vat_number = Factory(:company)
        end

        should "set payee vat_number if not set" do
          @supplier.update_attribute(:payee, @company_without_vat_number)
          @matcher.perform
          assert_equal @matcher.vat_number, @company_without_vat_number.reload.vat_number
        end
        
        should "update payee vat_number if set" do
          @supplier.update_attribute(:payee, @company)
          @matcher.perform
          assert_equal @matcher.vat_number, @company.reload.vat_number
        end
        
        should "send alert if updating payee vat_number and vat_number different" do
          AdminMailer.expects(:deliver_admin_alert!)
          @supplier.update_attribute(:payee, @company)
          @matcher.perform
        end
        
        should "not send alert if updating payee vat_number and vat_number same" do
          @company.update_attribute(:vat_number, @matcher.vat_number)
          AdminMailer.expects(:deliver_admin_alert!).never
          @supplier.update_attribute(:payee, @company)
          @matcher.perform
        end
        
        should "not update payee title" do
          old_title = @company_without_vat_number.title
          @matcher.perform
          assert_equal old_title, @company_without_vat_number.reload.title
        end
        
      end
    end
  end
  
  context "A CompanyNumberMatcher instance" do
    setup do
      @supplier = Factory(:supplier)
      @matcher = SupplierUtilities::CompanyNumberMatcher.new(:company_number => "ABOO1234", :supplier => @supplier)
    end

    should "store company_number as accessor" do
      assert_equal "ABOO1234", @matcher.company_number
    end

    should "store submitted supplier_id as instance_variable" do
      assert_equal @supplier.id, @matcher.instance_variable_get(:@supplier_id)
    end
    
    should "return supplier indentified with supplier id as supplier" do
      assert_equal @supplier, @matcher.supplier
    end
        
    context "when performing" do
      setup do
        @company = Factory(:company)
      end

      should "match or create company from number" do
        Company.expects(:match_or_create).with(:company_number => @matcher.company_number)
        @matcher.perform
      end
      
      should "associate found company with supplier" do
        Company.stubs(:match_or_create).returns(@company)
        @matcher.perform
        assert_equal @company, @supplier.reload.payee
      end
      
      context "and supplier already has payee" do
        setup do
          @another_company = Factory(:company)
          @supplier.update_attribute(:payee, @another_company)
          Company.stubs(:match_or_create)
        end
        
        context "and normalised company_number is same as company_number of payee" do
          setup do
            normalised_number = 'AB0001234'
            @supplier.payee.update_attribute(:company_number, normalised_number)
            Company.expects(:normalise_company_number).with(@matcher.company_number).returns(normalised_number)
            Company.expects(:normalise_company_number).with(@another_company.company_number).returns(normalised_number)
          end

          should "not match company from number" do
            Company.expects(:match_or_create).never
            @matcher.perform
          end
          
          should "not change payee company" do
            @matcher.perform
            assert_equal @another_company, @matcher.supplier.payee
          end
          
          should "not send alert" do
            AdminMailer.expects(:deliver_admin_alert!).never
            @matcher.perform
          end

        end
        
        context "and normalised company_number is different from company_number of payee" do

          should "not match company from number" do
            Company.expects(:match_or_create).never
            @matcher.perform
          end
          
          should "not change payee company" do
            @matcher.perform
            assert_equal @another_company, @matcher.supplier.payee
          end

          should "send alert" do
            AdminMailer.expects(:deliver_admin_alert!)
            @matcher.perform
          end

        end
                
      end
      
      context "and no company returned from matching or creating" do
        setup do
          Company.stubs(:match_or_create)
        end

        should "send alert" do
          AdminMailer.expects(:deliver_admin_alert!)
          @matcher.perform
        end
      end
    end
  end
end
require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  context "The Company class" do
    setup do
      @company = Factory(:company)
    end
  
    should have_many :supplying_relationships
  
    should have_db_column :title
    should have_db_column :company_number
    should have_db_column :url
    should have_db_column :normalised_title
    should have_db_column :status
    should have_db_column :wikipedia_url
    should have_db_column :company_type
    should have_db_column :incorporation_date
    should have_db_column :vat_number
    
    should 'mixin AddressMethods module' do
      assert @company.respond_to?(:address_in_full)
    end
    
    context "when validating" do
      should "require presence of company_number or vat_number" do
        company = Company.new(:company_number => '1234')
        assert company.valid?
        company.attributes = {:company_number => nil, :vat_number => 'ab123'}
        assert company.valid?
        company.vat_number = nil
        assert !company.valid?
      end
      
      should "validate uniqueness of non-blank company_number" do
        dup_company = Factory.build(:company, :company_number => @company.company_number)
        another_dup_company = Factory.build(:company, :company_number => nil, :vat_number => 'cd456')
        assert !dup_company.valid?
        assert_equal 'has already been taken', dup_company.errors[:company_number]
        @company.update_attributes(:company_number => nil, :vat_number => 'ab123' )
        assert another_dup_company.valid?
      end
      
      should "validate uniqueness of non-blank vat_number" do
        dup_company = Factory.build(:company, :company_number => '4567') # vat number is nil
        another_dup_company = Factory.build(:company, :company_number => nil, :vat_number => 'ab123')
        assert dup_company.valid? # don't check if nil
        @company.update_attributes(:company_number => nil, :vat_number => 'ab123' )
        assert !another_dup_company.valid?
        assert_equal 'has already been taken', another_dup_company.errors[:vat_number]
      end
      
      # should_validate_uniqueness_of :company_number
      # should_validate_uniqueness_of(:vat_number).case_insensitive
    end
    
    context "when normalising title" do
      should "normalise title" do
        TitleNormaliser.expects(:normalise_company_title).with('foo bar')
        Company.normalise_title('foo bar')
      end
      
      should "replace '&' with 'and'" do
        TitleNormaliser.expects(:normalise_company_title).with('foo and bar')
        Company.normalise_title('foo & bar')
      end
      
      should "replace '&' with no space with space-separated 'and'" do
        TitleNormaliser.expects(:normalise_company_title).with('foo and bar')
        Company.normalise_title('foo&bar')
      end
    end
    
    context "when normalising company_number" do
      should "add required leading zeros" do
        assert_equal '00001234', Company.normalise_company_number('1234')
        assert_equal '00001234', Company.normalise_company_number('001234')
      end
      
      should "return nil if company_number blank" do
        assert_nil Company.normalise_company_number(nil)
        assert_nil Company.normalise_company_number('')
      end
      
    end
    
    context "when getting from title" do
      should "find company that matches normalised title" do
        raw_title = ' Foo &  Bar Ltd.'
        Company.expects(:first).with(:conditions => {:normalised_title => TitleNormaliser.normalise_company_title(raw_title)}).returns(stub_everything)
        Company.from_title(raw_title)
      end
      
      should "return company that matching normalised title" do
        some_co = stub
        Company.stubs(:first).returns(some_co)
        assert_equal some_co, Company.from_title('Foo')
      end
      
      context "and no company matches normalised title" do
        setup do
          @company_attribs = {:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}
          CompanyUtilities::Client.any_instance.stubs(:company_from_name).returns(@company_attribs)
        end

        should "get companies matching name" do
          CompanyUtilities::Client.any_instance.expects(:company_from_name).with('Foo')
          Company.from_title('Foo')
        end
        
        should "create company" do
          assert_difference "Company.count", 1 do
            Company.from_title('Foo')
          end
        end
        
        should "return created company" do
          company = Company.from_title('Foo')
          assert !company.new_record?
          assert_kind_of Company, company
          assert_equal "SPIKES CAVELL & COMPANY LIMITED", company.title
          assert_equal "06398324", company.company_number
        end

        context "but no company is returned" do
          setup do
            CompanyUtilities::Client.any_instance.stubs(:company_from_name) # => returns nil still
          end
        
          should "not create company" do
            assert_no_difference "Company.count" do
              Company.from_title('Foo')
            end
          end
        end
      end
    end
        
    context "when matching or creating from params" do
      setup do
        @existing_company = Factory(:company, :company_number => "00012345")
        @existing_co_with_vat_no = Factory(:company, :company_number => nil, :vat_number => '1234')
      end

      should "return company with given company number" do
        assert_equal @existing_company, Company.match_or_create(:company_number => "00012345")
      end
      
      should "return company with given vat number" do
        assert_equal @existing_co_with_vat_no, Company.match_or_create(:vat_number => "1234")
      end
      
      should "return company that matches normalised version of company number" do
        assert_equal @existing_company, Company.match_or_create(:company_number => "12345")
        assert_equal @existing_company, Company.match_or_create(:company_number => "012345")
      end
      
      should "not add company to delayed_job queue for fetching more details" do
        Delayed::Job.expects(:enqueue).never
        Company.match_or_create(:company_number => "0123456")
      end
      
      context "and company doesn't exist" do
        
        should "create company with given company number" do
          assert_difference "Company.count", 1 do
            Company.match_or_create(:company_number => "07654321")
          end
          assert Company.find_by_company_number("07654321")
        end
        
        should 'normalize company_number when creating company' do
          c = Company.match_or_create(:company_number => "7654321")
          assert_equal "07654321", c.reload.company_number
        end
        
        should "create company with given vat_number" do
          assert_difference "Company.count", 1 do
            Company.match_or_create(:vat_number => "7654321")
          end
          assert Company.find_by_vat_number("7654321")
        end
        
        should 'assign other attributes' do
          c = Company.match_or_create(:company_number => "7654321", :url => 'http://foo.com', :wikipedia_url => 'http://en.wikipedia.org/wiki/foo')
          assert_equal 'http://foo.com', c.url
          assert_equal 'http://en.wikipedia.org/wiki/foo', c.wikipedia_url
        end
        
        should 'not create company number if no company number and no vat number' do
          c = Company.match_or_create(:url => 'http://foo.com', :wikipedia_url => 'http://en.wikipedia.org/wiki/foo')
          assert_nil c.company_number
        end
        
        should 'add company to delayed_job queue for fetching more details' do
          Delayed::Job.expects(:enqueue).with(kind_of(Company))
          Company.match_or_create(:company_number => "07654321")
        end

      end
    end
    
  end
  
  context "An instance of the Company class" do
    setup do
      @company = Factory(:company)
    end
    
    context "when returning title" do
  
      should "use title attribute by default" do
        @company.update_attribute(:title, 'Foo Incorp')
        assert_equal 'Foo Incorp', @company.title
      end
      
      should "use company number if title is nil" do
        assert_equal "Company number #{@company.company_number}", @company.title
      end
      
      should "use vat number if title and company_number is nil" do
        @company.update_attributes(:company_number => nil, :vat_number => 'GB1234')
        assert_equal "Company with VAT number GB1234", @company.title
      end
    end
    
    should "use title when converting to_param" do
      @company.title = "some title-with/stuff"
      assert_equal "#{@company.id}-some-title-with-stuff", @company.to_param
    end
  
    should "skip title when converting to_param if title doesn't exist" do
      assert_equal @company.id.to_s, @company.to_param
    end
  
    context "when saving" do
      should "normalise title" do
        @company.expects(:normalise_title)
        @company.save!
      end
  
      should "save normalised title" do
        @company.title = "Foo & Baz Ltd."
        @company.save!
        assert_equal "foo and baz limited", @company.reload.normalised_title
      end
      
      should "not save normalised title if title is nil" do
        @company.save!
        assert_nil @company.reload.normalised_title
      end
    end
    
    context "when populating basic info" do
      
      context "and company has company_number" do
        setup do
          resp_hash = {:title => 'FOOCORP', :status => 'active', :status => 'Active', :incorporation_date => '1990-02-21', :company_type => 'Private Limited Company', :address_in_full => "501 BEAUMONT LEYS LANE\nLEICESTER\nLEICESTERSHIRE\nLE4 2BN" }
          CompanyUtilities::Client.any_instance.stubs(:get_basic_info).returns(resp_hash)
        end

        should "fetch info using CompanyUtilities" do
          CompanyUtilities::Client.any_instance.expects(:get_basic_info).with(@company.company_number)
          @company.populate_basic_info
        end

        should "update company with info from CompanyUtilities" do
          @company.populate_basic_info
          assert_equal 'FOOCORP', @company.title
          assert_equal '1990-02-21'.to_date, @company.incorporation_date
          assert_equal 'Private Limited Company', @company.company_type
          assert_equal 'Active', @company.status
        end

        should 'add address for company' do
          @company.populate_basic_info
          assert_kind_of Address, address = @company.address
          assert_equal "501 BEAUMONT LEYS LANE, LEICESTER, LEICESTERSHIRE, LE4 2BN", address.in_full
        end
      end
  
      context "and company has vat_number" do
        setup do
          @vat_company = Company.create!(:vat_number => '12345')
          resp_hash = {:title => 'FOOCORP LTD', :address_in_full => "501 BEAUMONT LEYS LANE, LEICESTER, LEICESTERSHIRE, LE4 2BN" }
          CompanyUtilities::Client.any_instance.stubs(:get_vat_info).returns(resp_hash)
        end

        should "fetch info using CompanyUtilities" do
          CompanyUtilities::Client.any_instance.expects(:get_vat_info).with(@vat_company.vat_number)
          @vat_company.populate_basic_info
        end

        should "update company with info from CompanyUtilities" do
          @vat_company.populate_basic_info
          assert_equal 'FOOCORP LTD', @vat_company.title
        end

        should 'add address for company' do
          @vat_company.populate_basic_info
          assert_kind_of Address, address = @vat_company.address
          assert_equal "501 BEAUMONT LEYS LANE, LEICESTER, LEICESTERSHIRE, LE4 2BN", address.in_full
        end
      end
  
    end
  
    should 'alias populate_basic_info as perform' do
      @company.expects(:populate_basic_info)
      @company.perform
    end
    
    context 'when returning companies_house_url' do
      should "return companies open house url" do
        @company.company_number = '012345'
        assert_equal 'http://companiesopen.org/uk/012345/companies_house', @company.companies_house_url
      end
    end
  
  end
end

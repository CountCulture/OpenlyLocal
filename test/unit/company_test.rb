require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  context "The Company class" do
    setup do
      @company = Factory(:company)
    end
  
    should have_many :supplying_relationships
    should validate_presence_of :company_number
    should validate_uniqueness_of :company_number
  
    should have_db_column :title
    should have_db_column :company_number
    should have_db_column :url
    should have_db_column :normalised_title
    should have_db_column :status
    should have_db_column :wikipedia_url
    should have_db_column :company_type
    should have_db_column :incorporation_date
    
    should 'mixin AddressMethods module' do
      assert @company.respond_to?(:address_in_full)
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
    
    context "when matching title" do
      should "find company that matches normalised title" do
        raw_title = ' Foo &  Bar Ltd.'
        Company.expects(:first).with(:conditions => {:normalised_title => TitleNormaliser.normalise_company_title(raw_title)})
        Company.matches_title(raw_title)
      end
    end
        
    context "when matching or creating from params" do
      setup do
        @existing_company = Factory(:company, :company_number => "00012345")
      end

      should "return company with given company number" do
        assert_equal @existing_company, Company.match_or_create(:company_number => "00012345")
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
        
        should 'assign other attributes' do
          c = Company.match_or_create(:company_number => "7654321", :url => 'http://foo.com', :wikipedia_url => 'http://en.wikipedia.org/wiki/foo')
          assert_equal 'http://foo.com', c.url
          assert_equal 'http://en.wikipedia.org/wiki/foo', c.wikipedia_url
        end
        
        should 'not create company number if no company number' do
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

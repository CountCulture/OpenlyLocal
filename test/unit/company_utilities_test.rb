require 'test_helper'

class CompanyUtilitiesTest < ActiveSupport::TestCase

  context "A Client instance" do
    setup do
      @client = CompanyUtilities::Client.new
    end
    
    context "when getting basic info for company number" do
      setup do
        @dummy_json =<<-EOF
{"company":{"wikipedia_url":null,"name":"OFFICE DEPOT INTERNATIONAL (UK) LIMITED","country_code":"uk","company_number":"02472621","company_category":"Private Limited Company","updated_at":"2010-06-29T21:48:02Z","url":null,"logo_image_url":null,"id":65261,"company_status":"Active","address":"501 BEAUMONT LEYS LANE\\nLEICESTER\\nLEICESTERSHIRE\\nLE4 2BN","incorporation_date":"1990-02-21","created_at":"2010-06-29T21:48:02Z"}}
EOF
        @client.stubs(:_http_get).returns(@dummy_json)
      end

      should "return nil if company number blank?" do
        assert_nil @client.get_basic_info('')
        assert_nil @client.get_basic_info(nil)
      end
      
      should "fetch info from CompaniesOpenHouse" do
        @client.expects(:_http_get).with('http://companiesopen.org/uk/02472621.js')
        @client.get_basic_info('02472621')
      end
      
      should "return nil if problem parsing info" do
        @client.expects(:_http_get).with('http://companiesopen.org/uk/02472621.js').returns('foo"')
        assert_nil @client.get_basic_info('02472621')
      end
      
      should "return info from CompaniesOpenHouse as hash" do
        assert_kind_of Hash, resp = @client.get_basic_info('02472621')
        assert_equal "OFFICE DEPOT INTERNATIONAL (UK) LIMITED", resp[:title]
        assert_equal "Private Limited Company", resp[:company_type]
        assert_equal "501 BEAUMONT LEYS LANE\nLEICESTER\nLEICESTERSHIRE\nLE4 2BN", resp[:address_in_full]
        assert_equal "1990-02-21", resp[:incorporation_date]
        assert_equal "Active", resp[:status]
      end
      
      should 'ignore unwanted info' do
        assert_nil @client.get_basic_info('02472621')[:company_number]
      end
      
      should 'strip nil values from CompaniesOpenHouse' do
        assert !@client.get_basic_info('02472621').keys.include?(:wikipedia_url)
      end
    end
    
    context "when finding from name" do
      setup do
        @dummy_json =<<-EOF
[{"company":{"wikipedia_url":null,"name":"SPIKES CAVELL & COMPANY LIMITED","country_code":"uk","company_number":"06398324","company_category":"Private Limited Company","updated_at":"2010-07-05T20:59:11Z","url":null,"logo_image_url":null,"id":65724,"company_status":"Active","address":"1 NORTHBROOK PLACE\\nNEWBURY\\nBERKSHIRE\\nRG14 1DQ","incorporation_date":"2007-10-15","created_at":"2010-07-05T20:59:11Z"}},{"company":{"wikipedia_url":null,"name":"SPIKES CAVELL ANALYTIC LIMITED","country_code":"uk","company_number":"04917291","company_category":"Private Limited Company","updated_at":"2010-07-05T20:59:13Z","url":null,"logo_image_url":null,"id":65725,"company_status":"Active","address":"1 NORTHBROOK PLACE\\nNEWBURY\\nBERKSHIRE\\nRG14 1DQ","incorporation_date":"2003-10-01","created_at":"2010-07-05T20:59:13Z"}}]
EOF
        @client.stubs(:_http_get).returns(@dummy_json)
      end

      should "fetch info from CompaniesOpenHouse" do
        @client.expects(:_http_get).with('http://companiesopen.org/search?q=Foo+Bar&f=js')
        @client.find_company_from_name('Foo Bar')
      end
      
      should "return nil if problem parsing info" do
        @client.expects(:_http_get).with('http://companiesopen.org/search?q=Foo+Bar&f=js').returns('foo"')
        assert_nil @client.find_company_from_name('Foo Bar')
      end
      
      should "return info from CompaniesOpenHouse as array of hashes" do
        assert_kind_of Array, resp = @client.find_company_from_name('Foo Bar')
        assert_kind_of Hash, first_co = resp.first
        assert_equal "SPIKES CAVELL & COMPANY LIMITED", first_co[:title]
        assert_equal "06398324", first_co[:company_number]
        assert_equal "Private Limited Company", first_co[:company_type]
        # assert_equal "uk", first_co[:country_code]
        assert_equal "1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", first_co[:address_in_full]
        assert_equal "2007-10-15", first_co[:incorporation_date]
        assert_equal "Active", first_co[:status]
      end
      
      should 'strip nil values from CompaniesOpenHouse' do
        assert !@client.find_company_from_name('Foo Bar').first.keys.include?(:wikipedia_url)
      end
    end
  end
end
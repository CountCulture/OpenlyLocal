require 'test_helper'

class CompanyUtilitiesTest < ActiveSupport::TestCase

  context "A Client instance" do
    setup do
      @client = CompanyUtilities::Client.new
    end
    
#     context "when getting basic info for company number" do
#       setup do
#         @dummy_json =<<-EOF
# {"company":{"wikipedia_url":null,"name":"OFFICE DEPOT INTERNATIONAL (UK) LIMITED","country_code":"uk","company_number":"02472621","company_category":"Private Limited Company","updated_at":"2010-06-29T21:48:02Z","url":null,"logo_image_url":null,"id":65261,"company_status":"Active","address":"501 BEAUMONT LEYS LANE\\nLEICESTER\\nLEICESTERSHIRE\\nLE4 2BN","incorporation_date":"1990-02-21","created_at":"2010-06-29T21:48:02Z"}}
# EOF
#         @client.stubs(:_http_get).returns(@dummy_json)
#       end
# 
#       should "return nil if company number blank?" do
#         assert_nil @client.get_basic_info('')
#         assert_nil @client.get_basic_info(nil)
#       end
#       
#       should "fetch info from CompaniesOpenHouse" do
#         @client.expects(:_http_get).with('http://companiesopen.org/uk/02472621.js')
#         @client.get_basic_info('02472621')
#       end
#       
#       should "return nil if problem parsing info" do
#         @client.expects(:_http_get).with('http://companiesopen.org/uk/02472621.js').returns('foo"')
#         assert_nil @client.get_basic_info('02472621')
#       end
#       
#       should "return info from CompaniesOpenHouse as hash" do
#         assert_kind_of Hash, resp = @client.get_basic_info('02472621')
#         assert_equal "OFFICE DEPOT INTERNATIONAL (UK) LIMITED", resp[:title]
#         assert_equal "Private Limited Company", resp[:company_type]
#         assert_equal "501 BEAUMONT LEYS LANE\nLEICESTER\nLEICESTERSHIRE\nLE4 2BN", resp[:address_in_full]
#         assert_equal "1990-02-21", resp[:incorporation_date]
#         assert_equal "Active", resp[:status]
#       end
#       
#       should 'ignore unwanted info' do
#         assert_nil @client.get_basic_info('02472621')[:company_number]
#       end
#       
#       should 'strip nil values from CompaniesOpenHouse' do
#         assert !@client.get_basic_info('02472621').keys.include?(:wikipedia_url)
#       end
#     end
    
    context "when getting info from vat_number" do
      setup do
        @dummy_response = dummy_html_response(:eu_vat_number_success)
        
        @client.stubs(:_http_get).returns(@dummy_response)
        @company_attribs = {:status=>"Active", :company_number=>"06398324", :title=>"MASTERCRATE LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}
        CompanyUtilities::Client.any_instance.stubs(:find_company_by_name).returns(@company_attribs)
      end

      should "return nil if vat number blank?" do
        assert_nil @client.get_vat_info('')
        assert_nil @client.get_vat_info(nil)
      end

      should "fetch info from Eu Vat service" do
        @client.expects(:_http_get).with('http://ec.europa.eu/taxation_customs/vies/viesquer.do?ms=GB&iso=GB&vat=02472621').returns(@dummy_response)
        @client.get_vat_info('02472621')
      end

      should "return nil if problem parsing info" do
        @client.expects(:_http_get).with('http://ec.europa.eu/taxation_customs/vies/viesquer.do?ms=GB&iso=GB&vat=02472621').returns('foo"')
        assert_nil @client.get_vat_info('02472621')
      end

      should "return nil if vat number not found parsing info" do
        @client.expects(:_http_get).with('http://ec.europa.eu/taxation_customs/vies/viesquer.do?ms=GB&iso=GB&vat=02472621').returns(dummy_html_response(:eu_vat_number_failure))
        assert_nil @client.get_vat_info('02472621')
      end

      should "find company by name returned by Eu Vat Service" do
        @client.expects(:find_company_by_name).with('MASTERCRATE LTD')
        @client.get_vat_info('02472621')
      end
      
      should "return company info returned from finding by name" do
        assert_equal @company_attribs, @client.get_vat_info('02472621')
      end

      should "return company info returned from Eu VAT Service if no company found from comanies house]" do
        @client.stubs(:find_company_by_name)
        assert_kind_of Hash, resp = @client.get_vat_info('02472621')
        assert_equal "MASTERCRATE LTD", resp[:title]
        assert_equal "CANNON WHARFE, 35 EVELYN STREET, SURREY QUAYS, LONDON, SE8 5RT", resp[:address_in_full]
      end

    end

#     context "when finding possible companies from name" do
#       setup do
#         @dummy_json =<<-EOF
# [{"company":{"wikipedia_url":null,"name":"SPIKES CAVELL & COMPANY LIMITED","country_code":"uk","company_number":"06398324","company_category":"Private Limited Company","updated_at":"2010-07-05T20:59:11Z","url":null,"logo_image_url":null,"id":65724,"company_status":"Active","address":"1 NORTHBROOK PLACE\\nNEWBURY\\nBERKSHIRE\\nRG14 1DQ","incorporation_date":"2007-10-15","created_at":"2010-07-05T20:59:11Z"}},{"company":{"wikipedia_url":null,"name":"SPIKES CAVELL ANALYTIC LIMITED","country_code":"uk","company_number":"04917291","company_category":"Private Limited Company","updated_at":"2010-07-05T20:59:13Z","url":null,"logo_image_url":null,"id":65725,"company_status":"Active","address":"1 NORTHBROOK PLACE\\nNEWBURY\\nBERKSHIRE\\nRG14 1DQ","incorporation_date":"2003-10-01","created_at":"2010-07-05T20:59:13Z"}}]
# EOF
#         @client.stubs(:_http_get).returns(@dummy_json)
#       end
#       
#       # should "user CompaniesHouse library to find possible companies" do
#       #   CompaniesHouse.expects(:name_search).with('Foo Bar')
#       #   @client.find_possible_companies_from_name('Foo Bar')
#       # end
#       # 
#       # should "fetch info from CompaniesOpenHouse" do
#       #   @client.expects(:_http_get).with('http://companiesopen.org/search?q=Foo+Bar&f=js')
#       #   @client.find_possible_companies_from_name('Foo Bar')
#       # end
#       
#       should "return nil if problem parsing info" do
#         @client.expects(:_http_get).with('http://companiesopen.org/search?q=Foo+Bar&f=js').returns('foo"')
#         assert_nil @client.find_possible_companies_from_name('Foo Bar')
#       end
#       
#       should "return info from CompaniesOpenHouse as array of hashes" do
#         assert_kind_of Array, resp = @client.find_possible_companies_from_name('Foo Bar')
#         assert_kind_of Hash, first_co = resp.first
#         assert_equal "SPIKES CAVELL & COMPANY LIMITED", first_co[:title]
#         assert_equal "06398324", first_co[:company_number]
#         assert_equal "Private Limited Company", first_co[:company_type]
#         # assert_equal "uk", first_co[:country_code]
#         assert_equal "1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", first_co[:address_in_full]
#         assert_equal "2007-10-15", first_co[:incorporation_date]
#         assert_equal "Active", first_co[:status]
#       end
#       
#       should 'strip nil values from CompaniesOpenHouse' do
#         assert !@client.find_possible_companies_from_name('Foo Bar').first.keys.include?(:wikipedia_url)
#       end
#     end
# 
#     context "when finding company from name" do
#       setup do
#         @company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}]
#         @multi_company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}, 
#                                    {:status=>"Active", :company_number=>"04917291", :title=>"SPIKES CAVELL ANALYTIC LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2003-10-01"}]
#       end
# 
#       should 'search using CompaniesUtilities and name' do
#         CompanyUtilities::Client.any_instance.expects(:find_possible_companies_from_name).with('Foo Co')
#         CompanyUtilities::Client.new.company_from_name('Foo Co')
#       end
#       
#       context "and single company is returned" do
#         setup do
#           CompanyUtilities::Client.any_instance.stubs(:find_possible_companies_from_name).returns(@company_response)
#         end
# 
#         should "return company info" do
#           resp = CompanyUtilities::Client.new.company_from_name('Foo Co')
#           assert_equal @company_response.first, resp
#         end
#       end
#       
#       context "and several companies are returned" do
#         setup do
#           CompanyUtilities::Client.any_instance.stubs(:find_possible_companies_from_name).returns(@multi_company_response)
#         end
# 
#         should "match company matching normalised title" do
#           resp = CompanyUtilities::Client.new.company_from_name('Spikes Cavell Analytic Ltd')
#           assert_equal @multi_company_response[1], resp
#         end
#         
#         should "return nil if no match" do
#           assert_nil CompanyUtilities::Client.new.company_from_name('Spikes Cavell Foo Ltd')
#         end
#       end
#       
#       context "and no company is returned" do
#         setup do
#           CompanyUtilities::Client.any_instance.stubs(:find_possible_companies_from_name) # => returns nil still
#         end
#       
#         should "normally return nil" do
#           assert_nil CompanyUtilities::Client.new.company_from_name('Foo Co')
#         end
#       
#         context "and name has ampersand in it" do
# 
#           should "make second call replacing ampersand with 'and'" do
#             CompanyUtilities::Client.any_instance.expects(:find_possible_companies_from_name).with('Foo and Bar Ltd').returns(@company_response) # then returns company response
#             CompanyUtilities::Client.new.company_from_name('Foo & Bar Ltd')
#           end
#       
#           should "return company info" do
#             CompanyUtilities::Client.any_instance.stubs(:find_possible_companies_from_name).with('Foo and Bar Ltd').returns(@company_response)
#             resp = CompanyUtilities::Client.new.company_from_name('Foo & Bar Ltd')
#             assert_equal @company_response.first, resp
#           end
#           
#         end
#       end
# 
#     end
#     
    context "when finding company by name" do
      setup do
        @poss_match = stub_everything(:company_name => 'Foo and Bar', :data_set => "LIVE", :company_number => "12398397")
        @exact_match = stub_everything(:company_name => 'Foo Bar', :data_set => "LIVE",:search_match => "EXACT", :company_number => "06398324")
        @dissolved_co = stub_everything(:company_index_status => "DISSOLVED", :company_name => 'Old Foo Bar', :data_set => "LIVE", :company_number => "35398366")
        @companies_house_resp = stub_everything(:co_search_items => [@poss_match, @exact_match, @dissolved_co])
        @company_details_resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active")
        
    
        CompaniesHouse.stubs(:name_search).returns(@companies_house_resp)
        CompaniesHouse.stubs(:company_details).returns(@company_details_resp)
      end
    
      should "user CompaniesHouse library to find possible companies" do
        CompaniesHouse.expects(:name_search).with('Foo Bar').returns(@companies_house_resp)
        @client.find_company_by_name('Foo Bar')
      end
    
      should "turn ampersands into 'and'" do
        CompaniesHouse.expects(:name_search).with('Foo and Bar').returns(@companies_house_resp)
        @client.find_company_by_name('Foo & Bar')
      end
    
      should "return company that exactly matches" do
        expects_to_match_company_with_number(@exact_match.company_number)
        @client.find_company_by_name('Foo Bar')
      end
      
      should "return nil if no results" do
        CompaniesHouse.stubs(:name_search).returns(nil)
       assert_nil @client.find_company_by_name('Foo Bar')
      end
      
      should "get company details for matched company" do
        CompaniesHouse.expects(:company_details).with(@exact_match.company_number).returns(@company_details_resp)
        @client.find_company_by_name('Foo Bar')
      end
      
      should "return company details for matched company" do
        CompaniesHouse.expects(:company_details).with(@exact_match.company_number).returns(@company_details_resp)
        assert_equal( {:company_number=>"02481991", :title => 'Foo PLC', :status =>"Active"}, @client.find_company_by_name('Foo Bar'))
      end
      
      
      context "and no company exactly matches" do
        setup do
          @former_name_co = stub_everything(:company_index_status => "CNGOFNAME", :company_name => 'Foo Baz', :data_set => "FORMER", :company_number => "45398366", :search_match => 'EXACT')
          @another_former_name_co = stub_everything(:company_index_status => "CNGOFNAME", :company_name => 'Foo and Baz', :data_set => "FORMER", :company_number => "45398368")
          @former_resp = stub_everything(:co_search_items => [@former_name_co, @another_former_name_co])
          CompaniesHouse.stubs(:name_search).returns(stub_everything(:co_search_items => [@poss_match, @dissolved_co]))
        end
    
        should "return company which when normalised matches normalised title" do
          expects_to_match_company_with_number(@poss_match.company_number)
          @client.find_company_by_name('Foo & Bar')
        end
    
        should "search previous company names" do
          CompaniesHouse.expects(:name_search).with('Foo Baz', :data_set => 'FORMER').returns(@former_resp)
          @client.find_company_by_name('Foo Baz')
        end
        
        should "return company with formaer name that exactly matches" do
          expects_to_match_company_with_number(@former_name_co.company_number)
          CompaniesHouse.stubs(:name_search).with('Foo Baz', :data_set => 'FORMER').returns(@former_resp)
          @client.find_company_by_name('Foo Baz')
        end
        
        should "return company with former name that matches after normalising" do
          expects_to_match_company_with_number(@another_former_name_co.company_number)
          CompaniesHouse.stubs(:name_search).with('Foo & Baz', :data_set => 'FORMER').returns(stub_everything(:co_search_items => [@another_former_name_co, @dissolved_co]) )
          @client.find_company_by_name('Foo & Baz')
        end
    
        should "return nil if no company with former name matches" do
          CompaniesHouse.stubs(:name_search).with('Foo & Baz', :data_set => 'FORMER').returns(stub_everything(:co_search_items => [@another_former_name_co, @dissolved_co]) )
          assert_nil @client.find_company_by_name('Foo Far')
        end
      end
            
    end
    
    context "when getting company details from number" do
      setup do
        @full_comp_details_resp = stub_everything( :company_number=>"02481991", 
                                                   :company_name => 'Foo PLC', 
                                                   :company_status =>"Active", 
                                                   :company_category => 'Public Limited Company',
                                                   :previous_names => [stub(:con_date =>"2006-10-10", :company_name=>"VEOLIA ES ONYX LIMITED"),
                                                                       stub(:con_date =>"2006-02-03", :company_name=>"ONYX U.K. LIMITED")],
                                                   :reg_address  => stub(:address_lines => ["VEOLIA HOUSE", "154A PENTONVILLE ROAD", "LONDON", "N1 9PE"]),
                                                   :incorporation_date => "1990-03-16",
                                                   :sic_codes => stub(:sic_text=>"9305 - Other service activities"))
      end

      should "return nil if company_number blank" do
        assert_nil @client.company_details_for('')
        assert_nil @client.company_details_for(nil)
      end
      
      should 'get company details from CompaniesHouse' do
        CompaniesHouse.expects(:company_details).with('123456').returns(@full_comp_details_resp)
        @client.company_details_for('123456')
      end
      
      should "contain company details in form Company can accept" do
        CompaniesHouse.stubs(:company_details).returns(@full_comp_details_resp)
        company_details = @client.company_details_for('123456')
        assert_equal '02481991', company_details[:company_number]
        assert_equal 'Foo PLC', company_details[:title]
        assert_equal 'Active', company_details[:status]
        assert_equal ["9305 - Other service activities"], company_details[:sic_codes]
        assert_equal ['VEOLIA ES ONYX LIMITED', 'ONYX U.K. LIMITED'], company_details[:previous_names]
        assert_equal "VEOLIA HOUSE, 154A PENTONVILLE ROAD, LONDON, N1 9PE", company_details[:address_in_full]
        assert_equal "1990-03-16", company_details[:incorporation_date]
        assert_equal "Public Limited Company", company_details[:company_type]
      end
      
      should 'not raise error when some attribs missing from response' do
        resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active")
        CompaniesHouse.stubs(:company_details).returns(resp)
        assert_nothing_raised(Exception) { @client.company_details_for('12345') }
      end
      
      should 'return only non-nil attribs in response' do
        resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active")
        CompaniesHouse.stubs(:company_details).returns(resp)
        assert_equal({:company_number=>"02481991", :title => 'Foo PLC', :status =>"Active"}, @client.company_details_for('12345') )
      end
      
      should 'return array of sic_codes if multiple sic_codes returned' do
        resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active", :sic_codes => stub(:sic_texts => ["7031 - Real estate agencies","7032 - Manage real estate, fee or contract"]))
        CompaniesHouse.stubs(:company_details).returns(resp)
        assert_equal ["7031 - Real estate agencies","7032 - Manage real estate, fee or contract"], @client.company_details_for('12345')[:sic_codes]
      end
    end
  end
  
  private  
  def expects_to_match_company_with_number(number)
    resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active")
    CompaniesHouse.expects(:company_details).with(number).returns(resp)
  end
end
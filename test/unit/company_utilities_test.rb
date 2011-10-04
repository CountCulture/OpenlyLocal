require 'test_helper'

class CompanyUtilitiesTest < ActiveSupport::TestCase

  context "A Client instance" do
    setup do
      @client = CompanyUtilities::Client.new
    end
    
    
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

      should "return company info returned from Eu VAT Service if no company found from companies house" do
        @client.stubs(:find_company_by_name)
        assert_kind_of Hash, resp = @client.get_vat_info('02472621')
        assert_equal "MASTERCRATE LTD", resp[:title]
        assert_equal "CANNON WHARFE, 35 EVELYN STREET, SURREY QUAYS, LONDON, SE8 5RT", resp[:address_in_full]
      end

      should "remove trading as info from title returned from Eu VAT Service" do
        @client.expects(:_http_get).returns(dummy_html_response(:eu_vat_number_success_with_ta))
        @client.stubs(:find_company_by_name)
        assert_kind_of Hash, resp = @client.get_vat_info('02472621')
        assert_equal "MASTERCRATE LTD", resp[:title]
      end

    end

    context "when finding company by name" do
      setup do
        @poss_match = stub_everything(:company_name => 'Foo and Bar', :data_set => "LIVE", :company_number => "12398397")
        @exact_match = stub_everything(:company_name => 'Foo Bar', :data_set => "LIVE",:search_match => "EXACT", :company_number => "06398324")
        @dissolved_co = stub_everything(:company_index_status => "DISSOLVED", :company_name => 'Old Foo Bar', :data_set => "LIVE", :company_number => "35398366")
        @companies_house_resp = stub_everything(:co_search_items => [@poss_match, @exact_match, @dissolved_co])
        @company_details_resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active")
        
        @client.stubs(:search_companies_house_for).returns(@companies_house_resp)
        CompaniesHouse.stubs(:company_details).returns(@company_details_resp)
      end
    
      should "user CompaniesHouse library to find possible companies" do
        @client.expects(:search_companies_house_for).with('Foo Bar').returns(@companies_house_resp)
        @client.find_company_by_name('Foo Bar')
      end
    
      should "turn ampersands into 'and'" do
        @client.expects(:search_companies_house_for).with('Foo and Bar').returns(@companies_house_resp)
        @client.find_company_by_name('Foo & Bar')
      end
    
      should "return company that exactly matches" do
        expects_to_match_company_with_number(@exact_match.company_number)
        @client.find_company_by_name('Foo Bar')
      end
      
      should "return nil if no results" do
        @client.stubs(:search_companies_house_for).returns(nil)
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
      
      context "and company_details returns just company_type" do
        setup do
          @client.expects(:company_details_for).with(@exact_match.company_number).returns(:company_type => 'Industrial & Provident Society')
        end

        should "return matched company name and company number" do
          expected_co_info = {:company_number => @exact_match.company_number, :title => @exact_match.company_name, :company_type => 'Industrial & Provident Society'}
          assert_equal expected_co_info, @client.find_company_by_name('Foo Bar')
        end
      end
      
      context "and no company exactly matches" do
        setup do
          @former_name_co = stub_everything(:company_index_status => "CNGOFNAME", :company_name => 'Foo Baz', :data_set => "FORMER", :company_number => "45398366", :search_match => 'EXACT')
          @another_former_name_co = stub_everything(:company_index_status => "CNGOFNAME", :company_name => 'Foo and Baz', :data_set => "FORMER", :company_number => "45398368")
          @former_resp = stub_everything(:co_search_items => [@former_name_co, @another_former_name_co])
          @client.stubs(:search_companies_house_for).returns(stub_everything(:co_search_items => [@poss_match, @dissolved_co]))
        end
    
        should "return company which when normalised matches normalised title" do
          expects_to_match_company_with_number(@poss_match.company_number)
          @client.find_company_by_name('Foo & Bar')
        end
    
        should "search previous company names" do
          @client.expects(:search_companies_house_for).with('Foo Baz', :data_set => 'FORMER').returns(@former_resp)
          @client.find_company_by_name('Foo Baz')
        end
        
        should "return company with formaer name that exactly matches" do
          expects_to_match_company_with_number(@former_name_co.company_number)
          @client.stubs(:search_companies_house_for).with('Foo Baz', :data_set => 'FORMER').returns(@former_resp)
          @client.find_company_by_name('Foo Baz')
        end
        
        should "return company with former name that matches after normalising" do
          expects_to_match_company_with_number(@another_former_name_co.company_number)
          @client.stubs(:search_companies_house_for).with('Foo & Baz', :data_set => 'FORMER').returns(stub_everything(:co_search_items => [@another_former_name_co, @dissolved_co]) )
          @client.find_company_by_name('Foo & Baz')
        end
    
        should "return nil if no company with former name matches" do
          @client.expects(:search_companies_house_for).with('Foo Far', :data_set => 'FORMER').returns(stub_everything(:co_search_items => [@another_former_name_co, @dissolved_co]) )
          assert_nil @client.find_company_by_name('Foo Far')
        end

        should "return nil if no company returned for former name" do
          @client.expects(:search_companies_house_for).with('Foo Far').returns(stub_everything(:co_search_items => []))
          @client.expects(:search_companies_house_for).with('Foo Far', :data_set => 'FORMER')#.returns(stub_everything(:co_search_items => [@another_former_name_co, @dissolved_co]) )
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
      
      should "return nil if no details for company" do
        CompaniesHouse.stubs(:company_details).raises(CompaniesHouse::Exception)
        assert_nil @client.company_details_for('123456')
      end
      
      context "and company has IP prefix" do
        should "not make call to CompaniesHouse api" do
          CompaniesHouse.expects(:company_details).never
          @client.company_details_for('IP123456')
        end
        
        should "return company_type as 'Industrial & Provident Society'" do
          expected_result = {:company_type => 'Industrial & Provident Society'}
          assert_equal expected_result, @client.company_details_for('IP123456')
        end
      end
      
    end
  end
  
  context 'The Matcher module' do
    context "when matching company" do
      setup do
        @poss_companies = [ stub_everything(:company_name => 'FOO LTD', :company_number => '01234566', :company_index_status => 'DISSOLVED'), 
                           stub_everything(:company_name => 'BAR CORP PLC', :company_number => '23456789') ]
      end

      should "return nil if no possible companies" do
        assert_nil CompanyUtilities::Matcher.match_company(:name => 'foo')
      end
      
      should "return company where company name matches given name" do
        assert_equal @poss_companies[1], CompanyUtilities::Matcher.match_company(:name => 'BAR CORP PLC', :poss_companies => @poss_companies)
      end
      
      should "return company where normalised company name matches normalised given name" do
        assert_equal @poss_companies[0], CompanyUtilities::Matcher.match_company(:name => 'Foo Limited', :poss_companies => @poss_companies)
      end
      
      should "return company where exact match even if normalised company name is not the same" do
        @poss_companies << stub_everything(:company_name => 'FOO (UK) LTD', :company_number => '97979797', :search_match => "EXACT")
        assert_equal @poss_companies[2], CompanyUtilities::Matcher.match_company(:name => 'Foo UK Limited', :poss_companies => @poss_companies)
      end
      
      context "and multiple companies have same name" do
        setup do
        end

        should "match companies where company index status is nil in preference to other" do
          @poss_companies << stub_everything(:company_name => 'FOO LTD', :company_number => '97979797')
          assert_equal @poss_companies[2], CompanyUtilities::Matcher.match_company(:name => 'Foo Limited', :poss_companies => @poss_companies)
        end
        
        should "match companies where company number is numeric in preference to non-numeric" do
          @poss_companies += [ stub_everything(:company_name => 'FOO LTD', :company_number => 'NF979797'), 
                               stub_everything(:company_name => 'FOO LTD', :company_number => '97979797'),
                               stub_everything(:company_name => 'FOO LTD', :company_number => 'FC12345') ]
          assert_equal @poss_companies[3], CompanyUtilities::Matcher.match_company(:name => 'Foo Limited', :poss_companies => @poss_companies)
        end
      end
    end
  end
  
  private  
  def expects_to_match_company_with_number(number)
    resp = stub_everything( :company_number=>"02481991", :company_name => 'Foo PLC', :company_status =>"Active")
    CompaniesHouse.expects(:company_details).with(number).returns(resp)
  end
end
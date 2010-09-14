require 'test_helper'

class CharityUtilitiesTest < ActiveSupport::TestCase

  context "A Client instance" do
    setup do
      @base_url = CharityUtilities::Client::BaseUrl
      @client = CharityUtilities::Client.new(:charity_number => '123456')
    end

    should "store charity_number as accessor" do
      assert_equal '123456', @client.charity_number
    end
    
    context "when getting charity details" do
      setup do
        @dummy_response = dummy_html_response(:large_charity_main_page)
        @client.stubs(:_http_get).returns(@dummy_response)
      end

      should "get charity commission page for charity" do
        @client.expects(:_http_get).with(@base_url + 'SearchResultHandler.aspx?RegisteredCharityNumber=123456&SubsidiaryNumber=0').returns(@dummy_response)
        @client.get_details
      end
      
      should "return hash of info" do
        assert_kind_of Hash, @client.get_details
      end
      
      should "return basic info" do
        basic_info = @client.get_details
        assert_match /TO PREVENT THE PUBLIC/, basic_info[:activities]
      end
      
      context "and when charity is big one" do
        should 'extract assets and people info from front page' do
          info = @client.get_details
          assert_equal '2,089', info[:employees]
          assert_equal '', info[:volunteers]
          asset_info = info[:financial_breakdown][:assets]
          assert_equal '41,098,000', asset_info[:own_use_assets]
          assert_equal '48,964,000', asset_info[:long_term_investments]
          assert_equal '15,970,000', asset_info[:other_assets]
          assert_equal '-42,265,000', asset_info[:total_liabilities]
        end
                
        should 'extract income info from front page as part of financial_breakdown' do
          breakdown = @client.get_details[:financial_breakdown]
          assert income = breakdown[:income]
          assert_equal "119,122,000", income[:voluntary]
          assert_equal "9,929,000", income[:trading]
          assert_equal "3,066,000", income[:investment]
          assert_equal "24,103,000", income[:charitable]
          assert_equal "1,298,000", income[:other]
          assert_equal "0", income[:investment_gains]
        end
        
        should 'extract spending info from front page as part of financial_breakdown' do
          breakdown = @client.get_details[:financial_breakdown]
          assert income = breakdown[:spending]
          assert_equal "27,760,000", income[:generating_voluntary_income]
          assert_equal "778,000", income[:governance]
          assert_equal "3,557,000", income[:trading]
          assert_equal "121,000", income[:investment_management]
          assert_equal "121,864,000", income[:charitable_activities]
          assert_equal "7,720,000", income[:other]
        end
        
        should "get data from financial page listed on main page" do
          @client.expects(:finance_data_from).with(@base_url + 'FinancialHistory.aspx?RegisteredCharityNumber=216401&SubsidiaryNumber=0')
          @client.get_details
        end
        
        should "return data from financial page listed on main page" do
          dummy_financial_data = [{:accounts_date => '31 Mar 2009', :income => '1234'}]
          @client.stubs(:finance_data_from).returns(dummy_financial_data)
          info = @client.get_details
          assert_equal dummy_financial_data, info[:accounts]
        end
        
        should "get contact page listed on main page" do
          @client.expects(:_http_get).with(@base_url + 'ContactAndTrustees.aspx?RegisteredCharityNumber=216401&SubsidiaryNumber=0')
          @client.get_details
        end
        
        should "get framework page listed on main page" do
          @client.expects(:_http_get).with(@base_url + 'CharityFramework.aspx?RegisteredCharityNumber=216401&SubsidiaryNumber=0')
          @client.get_details
        end
      end
    end
    
    context "when extracting financial data from big charity financials page" do
      setup do
        @client.stubs(:_http_get).returns(dummy_html_response(:large_charity_financials_page))
      end

      # should "return nil if url blank" do
      #   assert_nil @client.finance_data_from(nil)
      # end
      
      should "get financials page" do
        @client.expects(:_http_get).with('foo.com').returns(dummy_html_response(:large_charity_financials_page))
        @client.finance_data_from('foo.com')
      end
      
      should "return array of financial years, most recent first" do
        assert_kind_of Array, financial_info = @client.finance_data_from('foo.com')
        assert_equal 5, financial_info.size
        assert_equal "31 Mar 2009", financial_info.first[:accounts_date]
      end
      
      should "assign financial info for each year to appropriate_keys" do
        first_year = @client.finance_data_from('foo.com').first
        assert_equal "£154,670,457", first_year[:income]
        assert_equal "£158,953,404", first_year[:spending]
        assert_equal "http://www.charitycommission.gov.uk/ScannedAccounts/Ends01\\0000216401_ac_20090331_e_c.pdf", first_year[:accounts_url]
        assert_equal "http://www.charitycommission.gov.uk/SIR/ENDS01\\0000216401_SIR_09_E.PDF", first_year[:sir_url]
      end
      
      should "flag whether year's accounts are consolidated" do
        financial_info = @client.finance_data_from('foo.com')
        assert financial_info.first[:consolidated]
        assert !financial_info.last[:consolidated]
      end
    end
    
    context "when extracting contact data from contacts page" do
      setup do
        @client.stubs(:_http_get).returns(dummy_html_response(:large_charity_contacts_page))
      end

      should "get contacts page" do
        @client.expects(:_http_get).with('foo.com').returns(dummy_html_response(:large_charity_contacts_page))
        @client.contact_data_from('foo.com')
      end
      
      should "return basic contact info" do
        assert_kind_of Hash, contact_info = @client.contact_data_from('foo.com')
        assert_equal 'http://www.nspcc.org.uk', contact_info[:website]
        assert_equal 'MS CATHERINE DIXON', contact_info[:contact_name]
        assert_equal 'N S P C C, NATIONAL CENTRE, 42 CURTAIN ROAD, LONDON, EC2A 3NH', contact_info[:address_in_full]
        assert_equal '020 7825 2500', contact_info[:telephone]
        assert_equal 'info@nspcc.org.uk', contact_info[:email]
      end
      
      should "return trustees" do
        assert_kind_of Array, trustees = @client.contact_data_from('foo.com')[:trustees]
        assert_equal 16, trustees.size
        assert_equal( {:full_name => 'DAME DENISE PLATT', :uid => '793946'}, trustees.first)
        assert_equal( {:full_name => 'MR MARK WOOD', :uid => '3625072'}, trustees.last)
      end
      # should "assign financial info for each year to appropriate_keys" do
      #   first_year = @client.finance_data_from('foo.com').first
      #   assert_equal "£154,670,457", first_year[:income]
      #   assert_equal "£158,953,404", first_year[:spending]
      #   assert_equal "http://www.charitycommission.gov.uk/ScannedAccounts/Ends01\\0000216401_ac_20090331_e_c.pdf", first_year[:accounts_url]
      #   assert_equal "http://www.charitycommission.gov.uk/SIR/ENDS01\\0000216401_SIR_09_E.PDF", first_year[:sir_url]
      # end
      # 
      # should "flag whether year's accounts are consolidated" do
      #   financial_info = @client.finance_data_from('foo.com')
      #   assert financial_info.first[:consolidated]
      #   assert !financial_info.last[:consolidated]
      # end
    end
    
    context "when extracting info from framework page" do
      setup do
        @client.stubs(:_http_get).returns(dummy_html_response(:large_charity_frameworks_page))
      end

      should "get contacts page" do
        @client.expects(:_http_get).with('foo.com').returns(dummy_html_response(:large_charity_frameworks_page))
        @client.frameworks_data_from('foo.com')
      end
      
      should "return basic info" do
        assert_kind_of Hash, framework_info = @client.frameworks_data_from('foo.com')
        assert_equal '01 April 1963', framework_info[:date_registered]
        assert_match /ROYAL CHARTER DATED 28 MAY 1895/, framework_info[:governing_document]
        assert_match /NSPCC/, framework_info[:other_names]
      end
    end
  end
end
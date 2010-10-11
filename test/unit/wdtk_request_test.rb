require 'test_helper'

class WdtkRequestTest < ActiveSupport::TestCase
  subject { @wdtk_request }
  
  context "The WdtkRequest class" do
    setup do
      @wdtk_request = Factory(:wdtk_request)
      @organisation = @wdtk_request.organisation
    end
    should validate_presence_of :organisation_id
    should validate_presence_of :organisation_type
    should validate_presence_of :request_name
    should validate_uniqueness_of :request_name
    should belong_to :organisation
    should belong_to :related_object
    
    should have_db_column :related_object_type
    should have_db_column :related_object_id
    
    should "by default return most recently updated first" do
      new_record = Factory(:wdtk_request, :organisation => @organisation)
      WdtkRequest.record_timestamps = false # update timestamp without triggering callbacks
      @wdtk_request.update_attribute(:updated_at, 1.day.ago)
      WdtkRequest.record_timestamps = true 
      assert_equal [new_record, @wdtk_request], WdtkRequest.all
    end
    
    context "should have stale named scope which" do
      setup do
        @stale_wdtk_req = Factory(:wdtk_request)
        WdtkRequest.update_all(["updated_at = ?", 28.hours.ago], :id => @stale_wdtk_req.id)
      end

      should "should return requests older last updated 24 hours ago or more" do
        assert_equal [@stale_wdtk_req], WdtkRequest.stale
      end
    end
    
    context "when fetching tagged requests" do
      setup do
        @council = Factory(:generic_council, :wdtk_name => 'bedford_borough_council')
        @another_council = Factory(:generic_council, :wdtk_name => 'birmingham_city_council')
        @another_org = Factory(:entity, :wdtk_name => 'wandsworth_borough_council')
        WdtkRequest.stubs(:_http_get).returns(dummy_json_response(:wdtk_search)) 
      end

      should "fetch all requests with given tag" do
        WdtkRequest.expects(:_http_get).with("http://www.whatdotheyknow.com/feed/search/tag:foo.json") 
        WdtkRequest.fetch_all_with_tags('foo')
      end
      
      should "fetch all requests with combination of given tags" do
        WdtkRequest.expects(:_http_get).with("http://www.whatdotheyknow.com/feed/search/tag:foo%20AND%20tag:bar.json") 
        WdtkRequest.fetch_all_with_tags(['foo', 'bar'])
      end
      
      should "create new wdtk_request records for new requests" do
        assert_difference "WdtkRequest.count", 3 do
          WdtkRequest.fetch_all_with_tags('foo')
        end
      end
      
      should "associate requests with organisations" do
        WdtkRequest.fetch_all_with_tags('foo')
        assert_equal @council, WdtkRequest.find_by_request_name('information_on_transaction_10125').organisation
      end
      
      context "and request already exists" do
        setup do
          @existing_request = Factory(:wdtk_request, :organisation =>  @another_council, :request_name => 'information_on_transaction_31442')
        end

        should "not create new wdtk_requests for existing requests" do
          assert_difference "WdtkRequest.count", 2 do
            WdtkRequest.fetch_all_with_tags('foo')
          end
        end
        
        should "update existing requests" do
          WdtkRequest.fetch_all_with_tags('foo')
          assert_equal 'waiting_response', @existing_request.reload.status
        end
        
      end
     
    end
    
    context "when processing" do
      setup do
        @another_council = Factory(:another_council, :wdtk_name => "bar_council")
      end
      
      should "fetch all requests tagged with openlylocal" do
        WdtkRequest.expects(:fetch_all_with_tags).with('openlylocal')
        WdtkRequest.process
      end
      
      should "update stale requests" do
        dummy_request = mock(:update_from_website => nil)
        WdtkRequest.expects(:stale).returns([dummy_request])
        WdtkRequest.process
      end
    end
    #   should "get wdtk info for councils" do
    #     WdtkRequest.expects(:update_wdtk_info_for).with(instance_of(Council)).twice # two councils in db
    #     WdtkRequest.process
    #   end
    #   
    #   should "not get wdtk info for councils without wdtk_name" do
    #     Factory(:tricky_council) # add council without wdtk_name
    #     WdtkRequest.expects(:update_wdtk_info_for).with(instance_of(Council)).twice # still only two councils used
    #     WdtkRequest.process
    #   end
    #   
    #   should "clean up defunct records" do
    #     WdtkRequest.expects(:clean_up)
    #     WdtkRequest.process
    #   end
    # end
    # 
    # context "when getting info for a council" do
    #   should "get first wdtk page for council" do
    #     WdtkRequest.expects(:_http_get).with("http://www.whatdotheyknow.com/body/foo_council")
    #     WdtkRequest.update_wdtk_info_for(@council)
    #   end
    #   
    #   should "parse html for requests" do
    #     WdtkRequest.stubs(:_http_get).returns("something")
    #     WdtkRequest.expects(:parse).with("something")
    #     WdtkRequest.update_wdtk_info_for(@council)
    #   end
    #   
    #   context "and parsing is successful" do
    #     setup do
    #       @existing_result = Factory(:wdtk_request, :url => "/request/parking_ticket_data_95", :council => @council)
    #       @dummy_parsing_results = [ {:title => "Dummy title", :url => "wdtk.com/dummy", :description => "Dummy desc", :status => "Done"},
    #                                  {:title => "New title", :url => @existing_result.url, :description => "New desc", :status => "Done"}]
    #       WdtkRequest.stubs(:parse).returns(:results => @dummy_parsing_results)
    #     end
    #     
    #     should "create new request" do
    #       WdtkRequest.update_wdtk_info_for(@council)
    #       new_wdtk_request = WdtkRequest.find_by_url("wdtk.com/dummy")
    #       assert_equal "Dummy title", new_wdtk_request.title
    #     end
    # 
    #     should "update existing requests with results" do
    #       WdtkRequest.update_wdtk_info_for(@council)
    #       assert_equal "New title", @existing_result.reload.title
    #     end
    #     
    #     should "not delete existing request not returned with results" do
    #       WdtkRequest.update_wdtk_info_for(@council)
    #       assert WdtkRequest.find(@wdtk_request.id)
    #     end
    #     
    #     should "get info from next page if next page is returned" do
    #       WdtkRequest.expects(:parse).returns(:results => @dummy_parsing_results, :next_page => "http://www.whatdotheyknow.com/body/foo_council?page=2") # expectation overrides stubbing
    #       WdtkRequest.expects(:_http_get).with("http://www.whatdotheyknow.com/body/foo_council")
    #       WdtkRequest.expects(:_http_get).with("http://www.whatdotheyknow.com/body/foo_council?page=2")
    #       WdtkRequest.update_wdtk_info_for(@council)
    #     end
    # 
    #   end
    #   
    #   context "and parsing is not successful" do
    #     setup do
    #       WdtkRequest.stubs(:_http_get) #=> returns nil
    #       WdtkRequest.update_wdtk_info_for(@council)
    #     end
    #     
    #     should_not_change( "wdtk_request_count" ) { WdtkRequest.count }
    # 
    #     should "not get next page" do
    #       WdtkRequest.expects(:_http_get) #=> called once only
    #       WdtkRequest.update_wdtk_info_for(@council)
    #     end
    # 
    #   end
    #   
    # end
    # 
    # context "when parsing page" do
    #   
    #   should "return nil if nothing to parser" do
    #     assert_nil WdtkRequest.parse(nil)
    #   end
    #   
    #   should "return hash" do
    #     assert_kind_of Hash, WdtkRequest.parse(dummy_html_response(:wdtk_council_page_1))
    #   end
    #   
    #   should "return array of hashes for results" do
    #     assert_kind_of Array, results = WdtkRequest.parse(dummy_html_response(:wdtk_council_page_1))[:results]
    #     assert_kind_of Hash, results.first
    #   end
    #   
    #   should "extract wdtk request info as hash" do
    #     wdtk_request_hash = WdtkRequest.parse(dummy_html_response(:wdtk_council_page_1))[:results].first
    #     assert_equal "http://www.whatdotheyknow.com/request/looked_after_children_under_cata_29", wdtk_request_hash[:url]
    #     assert_equal "Looked after children under catagory of emotional harm", wdtk_request_hash[:title]
    #     assert_equal "Awaiting response", wdtk_request_hash[:status]
    #     assert_equal "Under the freedom of information act I would like to know numerical statistics in order by year during the period of 1998 to 2008 (or as far back a...", wdtk_request_hash[:description]
    #   end
    #   
    #   should "remove anchor from request url" do
    #     wdtk_request_hash = WdtkRequest.parse(dummy_html_response(:wdtk_council_page_1))[:results][1]
    #     assert_equal "http://www.whatdotheyknow.com/request/birmingham_car_clampingremoval_p", wdtk_request_hash[:url]
    #   end
    #   
    #   should "extract next page url if it exists" do
    #     next_page = WdtkRequest.parse(dummy_html_response(:wdtk_council_page_1))[:next_page]
    #     assert_equal "http://www.whatdotheyknow.com/body/birmingham_city_council?page=2", next_page
    #   end
    #   
    #   should "return nil for next page url if it doesn't exist" do
    #     next_page = WdtkRequest.parse(dummy_html_response(:wdtk_council_last_page))[:next_page]
    #     assert_nil next_page
    #   end
    # end
    # 
    # context "when cleaning up" do
    #   should "remove wdtk_requests that haven't been updated for 2 weeks" do
    #     stale_request = Factory(:wdtk_request, :council => @council)
    #     WdtkRequest.record_timestamps = false # update timestamp without triggering callbacks
    #     stale_request.update_attribute(:updated_at, 2.months.ago)
    #     WdtkRequest.record_timestamps = true 
    #     WdtkRequest.send(:clean_up)
    #     assert_equal [@wdtk_request], WdtkRequest.all
    #   end
    # end
    # 
  end
  
  context "an instance of the WdtkRequest class" do
    setup do
      @organisation = Factory(:generic_council, :wdtk_name => 'foo_council')
      @wdtk_request = Factory(:wdtk_request, :organisation => @organisation)
    end
    
    context "when returning url" do

      should "build from request_name" do
        assert_equal "http://www.whatdotheyknow.com/request/#{@wdtk_request.request_name}", @wdtk_request.url
      end
    end

    context "when updating from website" do
      setup do
        WdtkRequest.stubs(:_http_get).returns(dummy_json_response(:wdtk_request_details))
      end

      should "request information on request from json version of url" do
        WdtkRequest.expects(:_http_get).with(@wdtk_request.url + '.json')
        @wdtk_request.update_from_website
      end
      
      should 'update title' do
        @wdtk_request.update_from_website
        assert_equal "Information on Transaction with CATCH 22 in Jul 2010", @wdtk_request.title
      end

      should 'update status' do
        @wdtk_request.update_from_website
        assert_equal "waiting_response", @wdtk_request.status
      end

      should "associate request with object identified in tags" do
        ft = Factory(:financial_transaction, :id => 163876)
        @wdtk_request.update_from_website
        assert_equal ft, @wdtk_request.reload.related_object
      end
            
    end
  end
end

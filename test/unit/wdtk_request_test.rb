require File.expand_path('../../test_helper', __FILE__)

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
        WdtkRequest.any_instance.stubs(:update_from_website)
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
      
      should "update requests from website" do 
        WdtkRequest.any_instance.expects(:update_from_website).times(3)
        WdtkRequest.fetch_all_with_tags('foo')
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
    
    context "when returning title" do

      should "return title if title exists" do
        assert_equal 'foo bar', Factory.build(:wdtk_request, :title => 'foo bar').title
      end
      
      should "return generic title referring to organisation if no title" do
        assert_equal "Freedom of Information request to #{@wdtk_request.organisation.title}", @wdtk_request.title
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

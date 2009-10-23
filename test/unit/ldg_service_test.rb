require 'test_helper'

class LdgServiceTest < ActiveSupport::TestCase
  subject { @ldg_service }
  context "The LdgService class" do
    setup do
      @ldg_service = Factory(:ldg_service) # category 'Foo 1'
      @council = Factory(:council, :ldg_id => 42)
    end
    should_validate_presence_of :category 
    should_validate_presence_of :lgsl
    should_validate_presence_of :lgil
    should_validate_presence_of :service_name
    should_validate_presence_of :authority_level
    should_validate_presence_of :url
    
    should "alias service_name as title" do
      assert_equal @ldg_service.service_name, @ldg_service.title
    end
    
    should "build url for service given council" do
      expected_url = "http://local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=31&LGIL=47&AgencyId=42&Type=Single"
      assert_equal expected_url, LdgService.new(:lgsl => 31, :lgil => 47).url_for(@council)
    end
    
    context "when returning destination_url for council" do
      setup do
        HTTPClient.any_instance.stubs(:get).returns(stub(:status => 404)) # just return 404 for everything by default
        @ldg_service.stubs(:url_for).with(@council).returns("http://foo.com")
      end
      
      should "use built url" do
        @ldg_service.expects(:url_for).with(@council).returns("http://foo.com")
        @ldg_service.destination_url(@council)
      end
      
      should "query built url" do
        HTTPClient.any_instance.expects(:get).with("http://foo.com")
        @ldg_service.destination_url(@council)
      end
      
      should "query url returned by directgov server" do
        HTTPClient.any_instance.expects(:get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
        HTTPClient.any_instance.expects(:get).with("http://bar.com").returns(stub(:status => 404))
        @ldg_service.destination_url(@council)
      end
      
      context "and good response from destination url" do
        setup do
          HTTPClient.any_instance.expects(:get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
          HTTPClient.any_instance.expects(:get).with("http://bar.com").returns(stub(:status => 200, :content => "<html><head><title>FooBar Page</title><head><body>Foo Baz</body></html>"))
        end
        
        should "return hash" do
          assert_kind_of Hash, @ldg_service.destination_url(@council)
        end
        
        should "return url in hash" do
          assert_equal "http://bar.com", @ldg_service.destination_url(@council)[:url]
        end
        
        should "return title in hash" do
          assert_equal "FooBar Page", @ldg_service.destination_url(@council)[:title]
        end
      end
      
      should "return nil if bad response from destination url" do
        HTTPClient.any_instance.expects(:get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
        HTTPClient.any_instance.expects(:get).with("http://bar.com").returns(stub(:status => 404))
        assert_nil @ldg_service.destination_url(@council)
      end
      
      should "return if timeout when getting info from LocalDirectGov" do
        HTTPClient.any_instance.expects(:get).with("http://foo.com").raises(HTTPClient::ConnectTimeoutError)
        assert_nil @ldg_service.destination_url(@council)
      end
      
      should "return if timeout when getting info from council" do
        HTTPClient.any_instance.expects(:get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
        HTTPClient.any_instance.expects(:get).with("http://bar.com").raises(HTTPClient::ConnectTimeoutError)
        assert_nil @ldg_service.destination_url(@council)
      end
    end
  end
end

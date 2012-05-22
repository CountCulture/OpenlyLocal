require File.expand_path('../../test_helper', __FILE__)

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
    should have_many :services
    
    should "alias service_name as title" do
      assert_equal @ldg_service.service_name, @ldg_service.title
    end
    
    should "build url for service given council" do
      expected_url = "http://local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=31&LGIL=47&AgencyId=42&Type=Single"
      assert_equal expected_url, LdgService.new(:lgsl => 31, :lgil => 47).url_for(@council)
    end
    
    context "when returning destination_url for council" do
      setup do
        @ldg_service.stubs(:url_for).with(@council).returns("http://foo.com")
      end
      
      context "in general" do
        setup do
          LdgService.any_instance.stubs(:_http_get).returns(stub(:status => 404)) # just return 404 for everything by default
          @ldg_service.stubs(:url_for).with(@council).returns("http://foo.com")
        end

        should "use built url" do
          @ldg_service.expects(:url_for).with(@council).returns("http://foo.com")
          @ldg_service.destination_url(@council)
        end

        should "query built url" do
          LdgService.any_instance.expects(:_http_get).with("http://foo.com")
          @ldg_service.destination_url(@council)
        end

        should "query url returned by directgov server" do
          LdgService.any_instance.expects(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
          LdgService.any_instance.expects(:_http_get).with("http://bar.com").returns(stub(:status => 404))
          @ldg_service.destination_url(@council)
        end
      end
      
      context "and good response from destination url" do
        setup do
          LdgService.any_instance.stubs(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
          LdgService.any_instance.stubs(:_http_get).with("http://bar.com").returns(stub(:status => 200, :content => "<html><head><title>FooBar Page</title><head><body>Foo Baz</body></html>"))
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
      
      context "and redirect from destination url" do
        setup do
          LdgService.any_instance.stubs(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
          LdgService.any_instance.stubs(:_http_get).with("http://bar.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com/foo"]}))
          LdgService.any_instance.stubs(:_http_get).with("http://bar.com/foo").returns(stub(:status => 200, :content => "<html><head><title>FooBar Page</title><head><body>Foo Baz</body></html>"))
        end
        
        should "follow redirect and return hash" do
          assert_kind_of Hash, @ldg_service.destination_url(@council)
        end
        
        should "follow redirect and return url in hash" do
          assert_equal "http://bar.com/foo", @ldg_service.destination_url(@council)[:url]
        end
        
        should "follow redirect and return title in hash" do
          assert_equal "FooBar Page", @ldg_service.destination_url(@council)[:title]
        end
      end
      
      context "and redirect to relative url from destination url" do
        setup do
          LdgService.any_instance.stubs(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
          LdgService.any_instance.stubs(:_http_get).with("http://bar.com").returns(stub(:status => 302, :header => {'location' => ["./foo"]}))
          LdgService.any_instance.stubs(:_http_get).with("http://bar.com/foo").returns(stub(:status => 200, :content => "<html><head><title>FooBar Page</title><head><body>Foo Baz</body></html>"))
        end
        
        should "follow redirect and return hash" do
          assert_kind_of Hash, @ldg_service.destination_url(@council)
        end
        
        should "follow redirect and return url in hash" do
          assert_equal "http://bar.com/foo", @ldg_service.destination_url(@council)[:url]
        end
        
        should "follow redirect and return title in hash" do
          assert_equal "FooBar Page", @ldg_service.destination_url(@council)[:title]
        end
      end
      
      should "return nil if bad response from destination url" do
        LdgService.any_instance.stubs(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
        LdgService.any_instance.stubs(:_http_get).with("http://bar.com").returns(stub(:status => 404))
        assert_nil @ldg_service.destination_url(@council)
      end
      
      should "return if timeout when getting info from LocalDirectGov" do
        LdgService.any_instance.stubs(:_http_get).with("http://foo.com").raises(HTTPClient::ConnectTimeoutError)
        assert_nil @ldg_service.destination_url(@council)
      end
      
      should "return if timeout when getting info from council" do
        LdgService.any_instance.stubs(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
        LdgService.any_instance.stubs(:_http_get).with("http://bar.com").raises(HTTPClient::ConnectTimeoutError)
        assert_nil @ldg_service.destination_url(@council)
      end
        
      should "return nil if prob parsing page for title" do
        LdgService.any_instance.stubs(:_http_get).with("http://foo.com").returns(stub(:status => 302, :header => {'location' => ["http://bar.com"]}))
        LdgService.any_instance.stubs(:_http_get).with("http://bar.com").returns(stub(:status => 200, :content => "<html><head><title>FooBar Page</title><head><body>Foo Baz</body></html>"))
        Nokogiri::HTML.expects(:parse).raises
        assert_nil @ldg_service.destination_url(@council)
      end
    end
  end
end

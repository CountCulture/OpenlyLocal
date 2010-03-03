require 'test_helper'

class NpiaUtilitiesTest < ActiveSupport::TestCase

  context "A Client instance" do
    setup do
      @client = NpiaUtilities::Client.new(:foo_method, :foo => "bar bam", :foo_1 => "baz")
    end

    should "store given method as method_name" do
      assert_equal :foo_method, @client.request_method
    end

    should "store given params as params" do
      assert_equal( {:foo => "bar bam", :foo_1 => "baz"}, @client.params)
    end
    
    context "when building request_url" do
      should "use base_url" do
        assert_match /^#{Regexp.escape(NpiaUtilities::Client::BaseUrl)}/, @client.request_url
      end
      
      should "use hyphenated version of method for path" do
        assert_match /\/foo-method/, @client.request_url
      end
      
      should "use hyphenated version of params for query" do
        assert_match /foo-1=baz/, @client.request_url
      end
      
      should "join query params with ampersand" do
        assert_match /&foo/, @client.request_url
      end
      
      should "URL escape query params" do
        assert_match /bar%20bam/, @client.request_url
      end
      
      should "use api_key as query param hyphenated version of params for query" do
        assert_match /\/?key=#{NPIA_API_KEY}/, @client.request_url
      end
    end
        
    context "when getting response" do
      setup do
        @dummy_response = dummy_xml_response(:npia_crime_area)
        @client.stubs(:request_url).returns("http://foo.com")
        @client.stubs(:_http_get).returns(@dummy_response)
      end
      
      should "build request url" do
        @client.expects(:request_url)
        @client.response
      end
      
      should "make get request using url" do
        @client.expects(:_http_get).with(regexp_matches(/#{@base_url}/)).returns(@dummy_response)
        @client.response
      end
      
      should "parse response" do
        Crack::XML.expects(:parse).with(@dummy_response).returns("police_api => {}")
        @client.response
      end
      
      should "return parsed response" do
        expected_response = Crack::XML.parse(@dummy_response)["police_api"]["response"]
        
        @client.expects(:_http_get).with(regexp_matches(/#{@base_url}/)).returns(@dummy_response)
        assert_equal expected_response, @client.response
      end
      
    end
  end
  
end
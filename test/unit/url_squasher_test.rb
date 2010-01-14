require 'test_helper'

class UrlSquasherTest < Test::Unit::TestCase

  context "The UrlSquasher class" do
    setup do
      dummy_response = %q({ "errorCode": 0, "errorMessage": "", "results": { "http://foo.com/bar": { "hash": "31IqMl", "shortKeywordUrl": "", "shortUrl": "http://bit.ly/15DlK", "userHash": "15DlK" } }, "statusCode": "OK" })
      UrlSquasher.any_instance.stubs(:_http_get).returns(dummy_response)
    end
    
    should "send request to Bit.ly" do
      UrlSquasher.any_instance.expects(:_http_get).with(regexp_matches(/api\.bit\.ly\/shorten/))
      UrlSquasher.new("http://foo.com/bar").result
    end
    
    context "and when sending request to shorten url" do
      should "include username" do
        UrlSquasher.any_instance.expects(:_http_get).with(regexp_matches(/#{BITLY_LOGIN}/))
        UrlSquasher.new("http://foo.com/bar").result
      end
      
      should "include api key" do
        UrlSquasher.any_instance.expects(:_http_get).with(regexp_matches(/#{BITLY_API_KEY}/))
        UrlSquasher.new("http://foo.com/bar").result
      end
      
      should "include url" do
        UrlSquasher.any_instance.expects(:_http_get).with(regexp_matches(/http\:\/\/foo\.com\/bar/))
        UrlSquasher.new("http://foo.com/bar").result
      end
      
      should "escape url" do
        UrlSquasher.any_instance.expects(:_http_get).with(regexp_matches(/http\:\/\/foo\.com\/bar%20baz/))
        UrlSquasher.new("http://foo.com/bar baz").result
      end
    end
    
    context "when getting result" do
      should "return nil if no response" do
        UrlSquasher.any_instance.expects(:_http_get) # => returns nil
        assert_nil UrlSquasher.new("http://foo.com/bar baz").result
      end

      should "extract squashed url from response" do
        assert_equal "http://bit.ly/15DlK", UrlSquasher.new("http://foo.com/bar").result
      end

      should "return nil if no results in response" do
        problem_response = %q({ "errorCode": 205, "errorMessage": "You tried to login with an invalid username/password.", "statusCode": "ERROR" })
        UrlSquasher.any_instance.expects(:_http_get).returns(problem_response)
        assert_nil UrlSquasher.new("http://foo.com/bar").result
      end

    end
          
  end
end

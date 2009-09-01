require 'test_helper'

class TweeterTest < Test::Unit::TestCase
  
  context "A Tweeter instance" do
    should "store tweet as instance_variable" do
      assert_equal "foo tweet", Tweeter.new("foo tweet").message
    end
    
    should "extract url from options" do
      assert_equal "http://foo.com", Tweeter.new("foo tweet", :url => "http://foo.com").instance_variable_get(:@url)
    end
    
    context "on perform" do
      setup do
        @tweeter = Tweeter.new("some message")
        @dummy_client = stub_everything
        Twitter::Client.stubs(:from_config).returns @dummy_client
      end
      
      should "create a new twitter client" do
        Twitter::Client.expects(:from_config).returns(stub_everything)
        @tweeter.perform
      end

      should "send given message to twitter" do
        @dummy_client.expects(:status).with(:post, "some message")
        @tweeter.perform
      end
      
      should "add get short url from url" do
        Twitter::Client.any_instance.stubs(:status)
        Tweeter.any_instance.expects(:shorten_url).with("http://foo.com").returns("http:://bit.ly/foo")
        Tweeter.new("some message", :url => "http://foo.com").perform
      end
      
      should "add short url when url given" do
        Tweeter.any_instance.stubs(:shorten_url).returns("http:://bit.ly/foo")
        @dummy_client.expects(:status).with(:post, "another message http:://bit.ly/foo")
        Tweeter.new("another message", :url => "http://foo.com").perform
      end
      
    end
    
  end

end

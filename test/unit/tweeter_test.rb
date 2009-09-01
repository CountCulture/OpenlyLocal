require 'test_helper'

class TweeterTest < Test::Unit::TestCase
  
  context "A Tweeter instance" do
    should "store tweet as instance_variable" do
      assert_equal "foo tweet", Tweeter.new("foo tweet").message
    end
    
    context "on perform" do
      setup do
        @tweeter = Tweeter.new("some message")
      end
      
      should "create a new twitter client" do
        Twitter::Client.expects(:from_config).returns(stub_everything)
        @tweeter.perform
      end

      should "send given message to twitter" do
        dummy_client = mock
        dummy_client.expects(:status).with(:post, "some message")
        Twitter::Client.stubs(:from_config).returns dummy_client
        @tweeter.perform
      end
      
    end
    
  end

end
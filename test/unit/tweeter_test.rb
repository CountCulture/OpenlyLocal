require 'test_helper'

class TweeterTest < Test::Unit::TestCase
  
  context "A Tweeter instance" do
    should "store tweet as instance_variable" do
      assert_equal "foo tweet", Tweeter.new("foo tweet").message
    end
    
    should "extract url from options" do
      assert_equal "http://foo.com", Tweeter.new("foo tweet", :url => "http://foo.com").instance_variable_get(:@url)
    end
    
    should "store other options as instance_variable" do
      assert_equal( {:foo => "bar"}, Tweeter.new("foo tweet", :url => "http://foo.com", :foo => "bar").options )
    end
    
    
    context "on perform" do
      setup do
        @tweeter = Tweeter.new("some message")
        @tweeter_with_options = Tweeter.new("some message", :foo => "bar")
        @dummy_client = stub_everything
        Twitter::Base.stubs(:new).returns @dummy_client
        YAML.stubs(:load_file).returns('test' => {'login' => 'foouser', 'password' => 'foopass'})
        UrlSquasher.any_instance.stubs(:result) # => returns nil
      end
      
      should "fetch login credentials from YAML file" do
        YAML.expects(:load_file).with(regexp_matches(/twitter\.yml/)).returns('test' => {'login' => 'foouser', 'password' => 'foopass'})
        @tweeter.perform
      end
      
      should "create new auth object" do
        Twitter::HTTPAuth.expects(:new).with('foouser', 'foopass')
        @tweeter.perform
      end
      
      should "create a new twitter client" do
        Twitter::Base.expects(:new).with(kind_of(Twitter::HTTPAuth)).returns(@dummy_client)
        @tweeter.perform
      end

      should "send given message to twitter" do
        @dummy_client.expects(:update).with("some message", anything)
        @tweeter.perform
      end
      
      should "send given options to twitter" do
        @dummy_client.expects(:update).with("some message", :foo => "bar")
        @tweeter_with_options.perform
      end
      
      should "get short url from url_squasher" do
        Twitter::Base.any_instance.stubs(:update)
        UrlSquasher.expects(:new).with("http://foo.com").returns(stub_everything)
        Tweeter.new("some message", :url => "http://foo.com").perform
      end
      
      should "add short url when url given" do
        UrlSquasher.any_instance.expects(:result).returns("http:://bit.ly/foo")
        @dummy_client.expects(:update).with("another message http:://bit.ly/foo", anything)
        Tweeter.new("another message", :url => "http://foo.com").perform
      end
      
      should "use unshortened URL if nil returned from url_squasher" do
        @dummy_client.expects(:update).with("another message http://foo.com", anything)
        Tweeter.new("another message", :url => "http://foo.com").perform
      end
      
    end
    
  end

end

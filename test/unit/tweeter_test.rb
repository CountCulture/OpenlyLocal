require File.expand_path('../../test_helper', __FILE__)

class TweeterTest < ActiveSupport::TestCase
  
  context "A Tweeter instance" do
    setup do
      @tweeter = Tweeter.new("some message")
      @tweeter_with_options = Tweeter.new("some message", :foo => "bar")
      @dummy_oauth_object = stub_everything
      @dummy_client = stub_everything
      @dummy_yaml_hash = {'test' => {'OpenlyLocal' => {'auth_token' => 'footoken', 'auth_secret' => 'foosecret'},
                                     'BarUser'     => {'auth_token' => 'bartoken', 'auth_secret' => 'barsecret'}}}
      Twitter::Client.stubs(:new).returns @dummy_client
      # Twitter::OAuth.stubs(:new).returns(@dummy_oauth_object)
      YAML.stubs(:load_file).returns(@dummy_yaml_hash)
      UrlSquasher.any_instance.stubs(:result) # => returns nil
    end
    
    should "store tweet as instance_variable" do
      assert_equal "foo tweet", Tweeter.new("foo tweet").message
    end
    
    should "extract url from options" do
      assert_equal "http://foo.com", Tweeter.new("foo tweet", :url => "http://foo.com").instance_variable_get(:@url)
    end
    
    should "store other options as instance_variable" do
      assert_equal( {:foo => "bar"}, Tweeter.new("foo tweet", :url => "http://foo.com", :foo => "bar").options )
    end
    
    should "store method as twitter_method" do
      assert_equal "do_something", Tweeter.new(:method => "do_something").twitter_method
    end
        
    context "when creating client" do
      setup do
        @tweeter = Tweeter.new("some message")
        @dummy_oauth_object = stub_everything
        @dummy_client = stub_everything
        @dummy_yaml_hash = {'test' => {'OpenlyLocal' => {'auth_token' => 'footoken', 'auth_secret' => 'foosecret'},
                                       'BarUser'     => {'auth_token' => 'bartoken', 'auth_secret' => 'barsecret'}}}
        Twitter::Client.stubs(:new).returns @dummy_client
        # Twitter::OAuth.stubs(:new).returns(@dummy_oauth_object)
        YAML.stubs(:load_file).returns(@dummy_yaml_hash)
      end

      should "get auth secret from YAML config file" do
        YAML.expects(:load_file).returns(@dummy_yaml_hash)
        @tweeter.client
      end
      
      should "create twitter client with app consumer token and secret" do
        Twitter::Client.expects(:new).with(has_entries(:consumer_key => TWITTER_CONSUMER_KEY,
                                                       :consumer_secret => TWITTER_CONSUMER_SECRET)).
                                      returns(@dummy_client)
        @tweeter.client
      end
      
      should "create twitter client using OpenlyLocal access token and secret  by default" do
        Twitter::Client.expects(:new).with(has_entries(:oauth_token => "footoken",
                                                       :oauth_token_secret => "foosecret")).
                                      returns(@dummy_client)
        # @dummy_oauth_object.expects(:authorize_from_access).with('footoken', 'foosecret')
        @tweeter.client
      end
      
      should "create twitter client with given user token and secret" do
        Twitter::Client.expects(:new).with(has_entries(:oauth_token => "bartoken",
                                                       :oauth_token_secret => "barsecret")).
                                      returns(@dummy_client)
        # @dummy_oauth_object.expects(:authorize_from_access).with('bartoken', 'barsecret')
        @tweeter.client('BarUser')
      end
      
      # should "create twitter client using oauth details" do
      #   Twitter::Client.expects(:new).with(@dummy_oauth_object)
      #   @tweeter.client
      # end
      # 
      # should "not create new client if client already exists" do
      #   @tweeter.client
      #   Twitter::OAuth.expects(:new).never
      #   @tweeter.client
      # end
    end
    
    context "when adding user to list" do
      setup do
        @dummy_client.stubs(:client).returns(stub_everything(:username => "mytwitterlogin"))
        Twitter.stubs(:user).returns("id" => "1234")
      end
      
      should "get id of user" do
        Twitter.expects(:user).with("foo").returns("id" => "1234")
        @tweeter.add_to_list(:user => "foo", :list => "foolist")
      end
      
      should "add to given list" do
        @dummy_client.expects(:list_add_member).with(anything, "foolist", anything)
        @tweeter.add_to_list(:user => "foo", :list => "foolist")
      end
      
      should "add user id" do
        @dummy_client.expects(:list_add_member).with(anything, anything, "1234")
        @tweeter.add_to_list(:user => "foo", :list => "foolist")
      end
      
      should "pass login name" do
        @dummy_client.expects(:list_add_member).with("mytwitterlogin", anything, anything)
        @tweeter.add_to_list(:user => "foo", :list => "foolist")
      end
    end
    
    context "when removing user from list" do
      setup do
        @dummy_client.stubs(:client).returns(stub_everything(:username => "mytwitterlogin"))
        Twitter.stubs(:user).returns("id" => "1234")
      end
      
      should "get id of user" do
        Twitter.expects(:user).with("foo").returns("id" => "1234")
        @tweeter.remove_from_list(:user => "foo", :list => "foolist")
      end
      
      should "add to given list" do
        @dummy_client.expects(:list_remove_member).with(anything, "foolist", anything)
        @tweeter.remove_from_list(:user => "foo", :list => "foolist")
      end
      
      should "add user id" do
        @dummy_client.expects(:list_remove_member).with(anything, anything, "1234")
        @tweeter.remove_from_list(:user => "foo", :list => "foolist")
      end
      
      should "pass login name" do
        @dummy_client.expects(:list_remove_member).with("mytwitterlogin", anything, anything)
        @tweeter.remove_from_list(:user => "foo", :list => "foolist")
      end
    end
    
    context "on perform" do
      
      context "and no twitter_method" do

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
      
      context "and twitter_method" do
        should "call method" do
          tweeter = Tweeter.new(:method => "foo_method")
          
          tweeter.expects(:foo_method)
          tweeter.perform
        end
        
        should "supply params in options method" do
          tweeter = Tweeter.new(:method => "foo_method", :foo => "bar")
          
          tweeter.expects(:foo_method).with(:foo => "bar")
          tweeter.perform
        end
      end
    end
    
  end

end

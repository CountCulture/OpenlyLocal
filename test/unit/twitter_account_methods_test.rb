require "test_helper"

class TestTwitteringModel <ActiveRecord::Base
  set_table_name "hyperlocal_sites"
  include TwitterAccountMethods
end

class TwitterAccountMethodsTest < ActiveSupport::TestCase
  
  context "A class that includes TwitterAccountMethods mixin" do
    subject { @new_twitter_account }
    
    setup do
      @test_model_with_twitter_account = TestTwitteringModel.create!
      @new_twitter_account = Factory(:twitter_account, :user => @test_model_with_twitter_account)
    end
    
    should "have one new_twitter_account" do
      assert_equal @new_twitter_account, @test_model_with_twitter_account.reload.new_twitter_account      
    end
    
    should "delegate twitter_account_name to associated twitter_account" do
      assert_equal @new_twitter_account.name, @test_model_with_twitter_account.twitter_account_name
    end
    
    should "return nil for twitter_account_name if no associated twitter_account" do
      assert_nil TestTwitteringModel.new.twitter_account_name
    end
    
    should "delegate twitter_account_url to associated twitter_account" do
      assert_equal @new_twitter_account.url, @test_model_with_twitter_account.twitter_account_url
    end
    
    should "return nil for twitter_account_name if no associated twitter_account" do
      assert_nil TestTwitteringModel.new.twitter_account_url
    end
    
  end
 
  context "An instance of a class that includes TwitterAccountMethods mixin" do
    setup do
      @test_model = TestTwitteringModel.create!
    end
    
    context "when calling twitter_account_name setter method" do
      setup do
      end
      
      should "create TwitterAccount" do
        assert_difference "TwitterAccount.count", 1 do
          @test_model.twitter_account_name = "foo"
        end
      end
      
      should "do nothing if name is blank" do
        assert_no_difference "TwitterAccount.count" do
          @test_model.twitter_account_name = ""
          @test_model.twitter_account_name = nil
        end
      end
      
      should "associate twitter account with instance" do
        @test_model.twitter_account_name = "foo"
        assert_equal @test_model.new_twitter_account, TwitterAccount.find_by_name("foo")
      end
      
      context "and instance already has associated twitter user" do
        setup do
          @test_model.twitter_account_name = "foo"
        end
        
        should "not create new TwitterAccount" do
          assert_no_difference "TwitterAccount.count"do
            @test_model.twitter_account_name = "bar"
          end
        end
        
        should "update existing twitter account with new name" do
          @test_model.twitter_account_name = "bar"
          assert_equal @test_model.reload.new_twitter_account, TwitterAccount.find_by_name("bar")
        end
      end
      
      should "have stub twitter_list_name" do
        assert_nil @test_model.twitter_list_name
        @test_model.twitter_account_name = "foo"
        assert_nil @test_model.twitter_list_name
      end
      
    end
    
  end
  
end

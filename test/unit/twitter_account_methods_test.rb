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
    end
        
  end
  
end

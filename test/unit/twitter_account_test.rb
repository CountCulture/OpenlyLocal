require 'test_helper'

class TwitterAccountTest < ActiveSupport::TestCase

  subject { @twitter_account }

  context "The TwitterAccount class" do
    setup do
      @twitter_account = Factory(:twitter_account)
    end

    should_validate_presence_of :name, :user_id, :user_type
    
    should_have_db_columns :twitter_id, :follower_count, :following_count, :last_tweet
    
    should "belong_to polymorphic user" do
      user = Factory(:member)
      assert_equal user, Factory(:twitter_account, :user => user).reload.user
    end
    
    should "alias name as title" do
      assert_equal "foo", Factory(:twitter_account, :name => "foo").title
    end

    should "return twitter url for account" do
      assert_equal "http://twitter.com/foo", Factory(:twitter_account, :name => "foo").url
    end
    
  end
  
  context "A TwitterAccount instance" do
    setup do
      @twitter_account = Factory(:twitter_account)
    end
    
    context "when updating" do
      should_eventually "get twitter details" do
        
      end
      
      should_eventually "update twitter account with details" do
        
      end
    end
    
    should_eventually "alias update as perform" do
      
    end
  end

end

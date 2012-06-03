require File.expand_path('../../test_helper', __FILE__)

class TestTwitterAccountUser <ActiveRecord::Base
  set_table_name "hyperlocal_sites"
  include TwitterAccountMethods
end

class TwitterAccountTest < ActiveSupport::TestCase

  subject { @twitter_account }

  context "The TwitterAccount class" do
    setup do
      @twitter_account = Factory(:twitter_account)
      @user = TestTwitterAccountUser.create!
    end

    [:name, :user_id, :user_type].each do |attribute|
      should validate_presence_of attribute
    end
    [:twitter_id, :follower_count, :following_count, :last_tweet].each do |column|
      should have_db_column column
    end
    
    should "belong_to polymorphic user" do
      assert_equal @user, Factory(:twitter_account, :user => @user).reload.user
    end
    
    should "alias name as title" do
      assert_equal "foo", Factory(:twitter_account, :name => "foo").title
    end

    should "return twitter url for account" do
      assert_equal "http://twitter.com/foo", Factory(:twitter_account, :name => "foo").url
    end
    
    should "delegate list_name to user" do
      @user.stubs(:twitter_list_name).returns("foo_list")
      assert_equal "foo_list", Factory(:twitter_account, :name => "foo", :user => @user).list_name
    end
    
  end
  
  context "A TwitterAccount instance" do
    setup do
      @user = TestTwitterAccountUser.create!
      @dummy_tweeter = Tweeter.new('foo')
    end
    
    context "with associated user with twitter_list_name" do
      setup do
        TestTwitterAccountUser.any_instance.stubs(:twitter_list_name).returns("foo_list")
        Tweeter.stubs(:new).with(kind_of(Hash)).returns(@dummy_tweeter)
      end

      should "add to twitter list when twitter_account is created" do
        Tweeter.expects(:new).with(:method => :add_to_list, :user => "foo", :list => "foo_list").returns(@dummy_tweeter)
        @user.twitter_account_name = "foo"
      end

      should "remove from twitter list when twitter_account is deleted" do
        @user.twitter_account_name = "foo"
        Tweeter.expects(:new).with(has_entries(:method => :remove_from_list, :user => 'foo', :list => 'foo_list')).returns(@dummy_tweeter)
        @user.reload.twitter_account.destroy
      end

      should "remove old account from twitter list when twitter_account name is changed" do
        @user.twitter_account_name = "foo"
        Tweeter.stubs(:new).with(has_entries(:method => :add_to_list)).returns(@dummy_tweeter)
        
        Tweeter.expects(:new).with(has_entries(:method => :remove_from_list, :user => 'foo', :list => 'foo_list')).returns(@dummy_tweeter)
        @user.twitter_account.update_attributes(:name => "bar")
      end

      should "add new account to twitter list when twitter_account name is changed" do
        @user.twitter_account_name = "foo"
        Tweeter.stubs(:new).with(has_entries(:method => :remove_from_list)).returns(@dummy_tweeter)
        Tweeter.expects(:new).with(has_entries(:method => :add_to_list, :user => 'bar', :list => 'foo_list')).returns(@dummy_tweeter)
        @user.twitter_account.update_attributes(:name => "bar")
      end
      
      should "not add to twitter list when twitter_account is updated but name is same" do
        @user.twitter_account_name = "foo"
        Tweeter.expects(:new).never
        @user.twitter_account.update_attributes(:following_count => 2)
      end
      
    end    

    context "with associated user with blank twitter_list_name" do
      setup do
        @user.stubs(:twitter_list_name).returns("")
      end

      should "not add to twitter list when twitter_account is created" do
        Tweeter.expects(:new).never
        @user.twitter_account_name = "foo"
      end

      should "not remove from twitter list when twitter_account is deleted" do
        @user.twitter_account_name = "foo"
        Tweeter.expects(:new).never
        @user.twitter_account.destroy
      end

      should "not remove or add old account from twitter list when twitter_account name is changed" do
        @user.twitter_account_name = "foo"
        Tweeter.expects(:new).never
        @user.twitter_account_name = "bar"
      end

    end
    
    context "when assigning name" do
      should "remove leading @" do
        assert_equal 'foo_bar', TwitterAccount.new(:name => '@foo_bar').name
      end
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

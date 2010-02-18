require 'test_helper'

class UserSubmissionTest < ActiveSupport::TestCase
  subject { @user_submission }

  context "The UserSubmission class" do
    setup do
      @user_submission = Factory(:user_submission)
    end
    
    should_belong_to :council
    should_belong_to :member
    should_validate_presence_of :council_id
    should_have_db_columns :twitter_account_name, :member_name, :blog_url, :facebook_account_name, :linked_in_account_name
    
    context "when setting twitter_account_name" do
      should "set as give name by default" do
        assert_equal "FooBar", UserSubmission.new(:twitter_account_name => "FooBar").twitter_account_name
      end
      
      should "strip out '@' sign if given" do
        assert_equal "FooBar", UserSubmission.new(:twitter_account_name => "@FooBar").twitter_account_name
      end
      
    end
  end
end

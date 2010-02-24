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
    should_have_db_columns :twitter_account_name, :member_name, :blog_url, :facebook_account_name, :linked_in_account_name, :approved
    should_not_allow_mass_assignment_of :approved
    
    should "require either member_name or member_id" do
      council = Factory(:another_council)
      assert !Factory.build(:user_submission, :member_id => nil, :member_name => nil, :council => council).valid?
      assert !Factory.build(:user_submission, :member_id => nil, :member_name => "", :council => council).valid?
      assert Factory.build(:user_submission, :member_id => 42, :member_name => nil, :council => council).valid?
      assert Factory.build(:user_submission, :member_id => nil, :member_name => "Fred", :council => council).valid?
    end
    
    should "give nice error meesage if both member_name and member_id blank" do
      submission = UserSubmission.new
      submission.save
      assert_equal "Member info is missing", submission.errors[:base]
    end
    
    context "when setting twitter_account_name" do
      should "set as give name by default" do
        assert_equal "FooBar", UserSubmission.new(:twitter_account_name => "FooBar").twitter_account_name
      end
      
      should "strip out '@' sign if given" do
        assert_equal "FooBar", UserSubmission.new(:twitter_account_name => "@FooBar").twitter_account_name
      end
      
    end
    
    context "when approving" do
      context "and member set" do
        setup do
          @member = Factory(:member, :council => @user_submission.council)
          @user_submission.update_attribute(:member, @member)
          @user_submission.approved = true
        end
        
        should "should update member from user_submission" do
          @member.expects(:update_from_user_submission).with(@user_submission)
          @user_submission.save!
        end
      end
      
      context "and member not set" do
        setup do
          @user_submission.approved = true
        end
        
        should "add errors to user submission" do
          @user_submission.save
          assert_match /Can\'t approve/, @user_submission.errors[:base]
        end
        
        should "return raise exception for updating_attributes bang method" do
          @user_submission.approved = true
          assert_raise(ActiveRecord::RecordInvalid) {@user_submission.update_attributes!(:twitter_account_name => "foo")}
        end
      end
      
    end

  end
end

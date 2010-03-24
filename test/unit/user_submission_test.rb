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
    
    context 'when returning unapproved submissions' do
      setup do
        @approved_user_submission = Factory(:user_submission, :council => Factory(:another_council))
        @approved_user_submission.update_attribute(:approved, true)
      end
      
      should 'return unapproved entries' do
        assert UserSubmission.unapproved.include?(@user_submission)
      end
      
      should 'not return approved entries' do
        assert !UserSubmission.unapproved.include?(@approved_user_submission)
      end
    end
    
    context "when approving" do
      context "and member set" do
        setup do
          @member = Factory(:member, :council => @user_submission.council)
          @user_submission.update_attribute(:member, @member)
        end
        
        should "should update member from user_submission" do
          @member.expects(:update_from_user_submission).with(@user_submission)
          @user_submission.approve
        end
        
        should "update submission as approved" do
          @user_submission.approve
          assert @user_submission.reload.approved?
        end
        
        should 'tweet about list addition when twitter_account is created' do
          dummy_tweeter = Tweeter.new('foo')
          Tweeter.stubs(:new).with(kind_of(Hash)).returns(dummy_tweeter)
          
          @user_submission.update_attribute(:twitter_account_name, 'foo')
          Tweeter.expects(:new).with(regexp_matches(/has been added to @OpenlyLocal #ukcouncillors/), anything).returns(dummy_tweeter)
          @user_submission.approve
        end
        
        should 'not tweet about list addition when no twitter_account' do
          Tweeter.expects(:new).never
          @user_submission.approve
        end
      end
      
      context "and member not set" do
        should "add errors to user submission" do
          @user_submission.approve
          assert_match /Can\'t approve/, @user_submission.errors[:member_id]
        end
        
        should "should update submission as approved" do
          @user_submission.approve
          assert !@user_submission.approved?
        end
        
        should 'not tweet about list addition' do
          Tweeter.expects(:new).never
          @user_submission.approve
        end
      end
      
    end

  end
end

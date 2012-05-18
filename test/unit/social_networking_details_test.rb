require File.expand_path('../../test_helper', __FILE__)

class SocialNetworkingDetailsTest < ActiveSupport::TestCase
  
  context "A SocialNetworkingDetails instance" do
    setup do
      @social_networking_details = SocialNetworkingDetails.new
    end
    
    should 'have blog_url accessor' do
      assert @social_networking_details.respond_to?(:blog_url)
      assert @social_networking_details.respond_to?(:blog_url=)
    end
    
    should 'have website accessor' do
      assert @social_networking_details.respond_to?(:website)
      assert @social_networking_details.respond_to?(:website=)
    end
    
    should 'have twitter_account_name accessor' do
      assert @social_networking_details.respond_to?(:twitter_account_name)
      assert @social_networking_details.respond_to?(:twitter_account_name=)
    end
    
    should 'have facebook_account_name accessor' do
      assert @social_networking_details.respond_to?(:facebook_account_name)
      assert @social_networking_details.respond_to?(:facebook_account_name=)
    end
    
    context 'when approving' do
      setup do
        @user_submission = Factory(:user_submission)
        @rich_social_networking_details = @user_submission.submission_details
        @item = @user_submission.item
      end
      
      should 'update item associated with user_submission with social networking details' do
        @item.expects(:update_social_networking_details).with(@rich_social_networking_details)
        
        @rich_social_networking_details.approve(@user_submission)
      end
      
      should 'return true if item successfully updated' do
        @item.expects(:update_social_networking_details).with(@rich_social_networking_details).returns(true)
        assert @rich_social_networking_details.approve(@user_submission)
      end
      
      context "and problem updating from user_submission" do
        setup do
          @item.stubs(:update_social_networking_details).with(@rich_social_networking_details).raises
        end
      
        should "not raise exception" do
          assert_nothing_raised(Exception) { @rich_social_networking_details.approve(@user_submission) }
        end
        
        should "return false" do
          assert !@rich_social_networking_details.approve(@user_submission)
        end
      end
    end

  end
end
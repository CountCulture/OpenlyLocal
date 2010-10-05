require 'test_helper'

class MembersHelperTest < ActionView::TestCase
  include ApplicationHelper
  context 'social_networking_link_for member' do
    setup do
      @member = Factory(:member)
      @member.facebook_account_name = 'bar'
    end
    
    should 'return single_social networking links for member if only one' do
      assert_equal "#{facebook_link_for(@member.facebook_account_name)}", social_networking_links_for(@member)
    end 
    
    should 'show link to add social_networking_info if none known' do
      @member.facebook_account_name = nil
      assert_equal "None known. #{link_to('Add social networking info now?', new_user_submission_path(:user_submission => {:item_id => @member.id, :item_type => 'Member', :submission_type => 'social_networking_details'}))}", social_networking_links_for(@member)
    end
    
    should 'return all social networking links for member' do
      @member.twitter_account_name = 'foo'
      assert_equal "#{twitter_link_for(@member.twitter_account_name)} #{facebook_link_for(@member.facebook_account_name)}", social_networking_links_for(@member)
    end
  end
end

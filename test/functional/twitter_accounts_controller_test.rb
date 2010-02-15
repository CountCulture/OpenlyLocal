require 'test_helper'

class TwitterAccountsControllerTest < ActionController::TestCase
  def setup
    @twitter_account = Factory(:twitter_account)
    @user = @twitter_account.user #  => a hyperlocal_site
    @council = Factory(:council)
    @member = Factory(:member, :council => @council)
    @tweeting_council_account = Factory(:twitter_account, :user => @council)
    @tweeting_member_account = Factory(:twitter_account, :user => @member)
  end
  
  context "on GET to :index" do
    context "with given user_type" do
      setup do
        get :index, :user_type => "hyperlocal_sites"
      end

      should_assign_to(:twitter_accounts) { [@twitter_account] }
      should_respond_with :success
      should_render_template :index
      should "list twitter accounts" do
        assert_select "li a", @twitter_account.name
      end

      should "show share block" do
        assert_select "#share_block"
      end

      # should "show api block" do
      #   assert_select "#api_info"
      # end
      
      should 'show title' do
        assert_select "title", /twitter accounts/i
      end
    end
    
    context "with no given user_type" do
      should "raise exception" do
        assert_raise(NoMethodError) { get :index }
      end
    end
  end

  # show test
  context "on GET to :show" do
    setup do
      get :show, :id => @twitter_account.id
    end
  
    should_assign_to(:twitter_account) { @twitter_account}
    should_respond_with :success
    should_render_template :show
    should_render_with_layout
  
    should "show title" do
      assert_select 'title', /twitter account for #{@user.title}/i
    end
    
    should "link to user" do
      assert_select 'a.hyperlocal_site_link', @user.title
    end
    
  end
end

require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  
  context "on GET to :index" do
    context "with authentication" do
      setup do
        @unapproved_site = Factory(:hyperlocal_site)
        @approved_site = Factory(:approved_hyperlocal_site)
        stub_authentication
        get :index
      end

      should_respond_with :success
      should_render_template :index
      should_not_set_the_flash
      should_assign_to(:hyperlocal_sites) {[@unapproved_site]}

      should "show admin in title" do
        assert_select "title", /admin/i
      end
      
      should "list unapproved hyperlocal sites" do
        # p HyperlocalSite.all
        # puts css_select("#hyperlocal_sites")
        assert_select "#hyperlocal_sites li a", /#{@unapproved_site.title}/
      end
    end 
    
    context "without authentication" do
      setup do
        get :index
      end

      should_respond_with 401
    end
    
  end
end

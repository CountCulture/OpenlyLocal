require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  
  context "on GET to :index" do
    context "with authentication" do
      setup do
        @unapproved_site = Factory(:hyperlocal_site)
        @approved_site = Factory(:approved_hyperlocal_site)
        @another_council = Factory(:another_council)
        @user_submission = Factory(:user_submission)
        @council_contact = Factory(:council_contact, :council => @another_council)
        stub_authentication
        get :index
      end

      should respond_with :success
      should render_template :index
      should_not set_the_flash
      should_assign_to(:hyperlocal_sites) {[@unapproved_site]}
      should_assign_to(:user_submissions) {[@user_submission]}

      should "show admin in title" do
        assert_select "title", /admin/i
      end
      
      should "list unapproved hyperlocal sites" do
        assert_select "#hyperlocal_sites li a", /#{@unapproved_site.title}/
      end
      
      should "list user_submissions" do
        assert_select "#user_submissions li", /#{@user_submission.title}/
      end
      
      should "list councils without wards" do
        assert_select "#councils_without_wards li a", /#{@another_council.name}/
      end
      
      should "list unapproved council contacts" do
        assert_select "#council_contacts", /#{@council_contact.name}/
      end
      
    end 
    
    context "without authentication" do
      setup do
        get :index
      end

      should respond_with 401
    end
    
  end
end

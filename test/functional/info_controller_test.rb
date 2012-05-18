require File.expand_path('../../test_helper', __FILE__)

class InfoControllerTest < ActionController::TestCase

  context "on GET to :about_us" do
    setup do
      get :about_us
    end
    should respond_with :success
    should render_template :about_us
    should render_with_layout
    should "show pretty version of action name in title" do
      assert_select "title", /About Us :: Info/
    end
  end
  
  context "on GET to :resources" do
    setup do
      get :resources
    end
    should respond_with :success
    should render_template :resources
    should render_with_layout
    should "show pretty version of action name in title" do
      assert_select "title", /Resources :: Info/
    end
  end
  
  context "on GET to :vocab" do
    setup do
      get :vocab
    end
    should respond_with :success
    should render_template :vocab
    should_not render_with_layout
  end
  
  context "on GET to :licence_info" do
    setup do
      get :licence_info
    end
    should respond_with :success
    should render_template :licence_info
    should render_with_layout
  end
  
  context "on GET to :api" do
    setup do
      Factory(:council)
      get :api
    end
    should respond_with :success
    should render_template :api
    should render_with_layout
    should assign_to :sample_council
    
    should "show pretty version of action name in title" do
      assert_select "title", /Api :: Info/
    end
  end
  
end

require 'test_helper'

class InfoControllerTest < ActionController::TestCase

  context "on GET to :about_us" do
    setup do
      get :about_us
    end
    should_respond_with :success
    should_render_template :about_us
    should_render_with_layout
    should "show pretty version of action name in title" do
      assert_select "title", /About Us :: Info/
    end
  end
  
  context "on GET to :resources" do
    setup do
      get :resources
    end
    should_respond_with :success
    should_render_template :resources
    should_render_with_layout
    should "show pretty version of action name in title" do
      assert_select "title", /Resources :: Info/
    end
  end
  
  context "on GET to :vocab" do
    setup do
      get :vocab
    end
    should_respond_with :success
    should_render_template :vocab
    should_render_without_layout
  end
  
  context "on GET to :licence_info" do
    setup do
      get :licence_info
    end
    should_respond_with :success
    should_render_template :licence_info
    should_render_with_layout
  end
  
  context "on GET to :api" do
    setup do
      Factory(:council)
      get :api
    end
    should_respond_with :success
    should_render_template :api
    should_render_with_layout
    should_assign_to :sample_council
    
    should "show pretty version of action name in title" do
      assert_select "title", /Api :: Info/
    end
  end
  
end

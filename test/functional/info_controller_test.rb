require 'test_helper'

class InfoControllerTest < ActionController::TestCase

  context "on GET to :about_us" do
    setup do
      get :about_us
    end
    should_respond_with :success
    should_render_template :about_us
    should_render_with_layout
    
  end
end

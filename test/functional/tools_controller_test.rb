require 'test_helper'

class ToolsControllerTest < ActionController::TestCase
  
  # gadget test
  context "on GET to :gadget" do
    setup do
      @council = Factory(:council)
      @member = Factory(:member, :council => @council)
      @another_council = Factory(:another_council)
    end
    
    context "with basic request" do
      setup do
        get :gadget, :format => "xml"
      end
  
      should_assign_to(:councils) { [@council]} # only parsed councils
      should_respond_with :success
      should_render_template :gadget
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      
      should "list all parsed councils" do
        assert_select "UserPref>EnumValue[display_value=?]",  @council.name
      end
      
      should "include code for gadget" do
        assert_match /script type=\"text\/javascript/,  @response.body
      end
      
      should_eventually "cache action" do
        
      end
    end
  end
end

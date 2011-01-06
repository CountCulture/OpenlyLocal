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
  
      should assign_to(:councils) { [@council]} # only parsed councils
      should respond_with :success
      should render_template :gadget
      should_render_without_layout
      should respond_with_content_type 'application/xml'
      
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
  
  context "on GET to :gadget_test" do
    setup do
      @council = Factory(:council)
      @member = Factory(:member, :council => @council)
      @another_council = Factory(:another_council)
      get :gadget_test, :format => "xml"
    end
      
    should assign_to(:councils) { [@council]} # only parsed councils
    should respond_with :success
    should render_template :gadget
    should_render_without_layout
    should respond_with_content_type 'application/xml'
  end
    
  # ning test
  context "on GET to :ning" do
    setup do
      @council = Factory(:council)
      @member = Factory(:member, :council => @council)
      @another_council = Factory(:another_council)
    end
    
    context "with basic request" do
      setup do
        get :ning, :format => "xml"
      end
  
      should assign_to(:councils) { [@council]} # only parsed councils
      should respond_with :success
      should render_template :ning
      should_render_without_layout
      should respond_with_content_type 'application/xml'
      
      should "list namespace for module" do
        assert_select "Module[xmlns:ning='http://developer.ning.com/opensocial/']"
      end
      
      # should "list all parsed councils" do
      #   assert_select "UserPref>EnumValue[display_value=?]",  @council.name
      # end
      
      should_eventually "include code for gadget" do
        assert_match /script type=\"text\/javascript/,  @response.body
      end
      
      should_eventually "cache action" do
        
      end
    end
    

  end
  
  # widget test
  context "on GET to :widget with council_id" do
    setup do
      @council = Factory(:council)
      @member = Factory(:member, :council => @council)
      @another_council = Factory(:another_council)
      get :widget, :format => "js", :council_id => @council.id
    end

    should assign_to(:council) { @council}
    should respond_with :success
    should render_template :widget
    should_render_without_layout
    should respond_with_content_type 'text/javascript'
  end

  # context "on GET to :ning_test" do
  #   setup do
  #     @council = Factory(:council)
  #     @member = Factory(:member, :council => @council)
  #     @another_council = Factory(:another_council)
  #     get :ning_test, :format => "xml"
  #   end
  #     
  #   should assign_to(:councils) { [@council]} # only parsed councils
  #   should respond_with :success
  #   should render_template :gadget
  #   should_render_without_layout
  #   should respond_with_content_type 'application/xml'
  # end
    
  
end

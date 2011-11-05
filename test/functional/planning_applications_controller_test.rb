require 'test_helper'

class PlanningApplicationsControllerTest < ActionController::TestCase

  should "route all_councils to index with include_unparsed true" do
    assert_routing("planning", {:controller => "planning_applications", :action => "overview"})
    assert_routing("planning_applications/1234", {:controller => "planning_applications", :action => "show", :id => '1234'})
  end

  context "on GET to :overview" do
    setup do
      get :overview
    end

    # should assign_to(:planning_application) { @planning_application }
    should respond_with :success
    should render_template :overview
    # should assign_to(:organisation) { @organisation }

    # should "show entity name in title" do
    #   assert_select "title", /#{@planning_application.title}/
    # end
  
    # should "show api block" do
    #   assert_select "#api_info"
    # end
  end

  context "on GET to :show" do
    setup do
      @planning_application = Factory(:planning_application)
      @another_planning_application = Factory(:planning_application)      
    end
    
    context "in general" do
      setup do
        get :show, :id => @planning_application.id
      end

      should assign_to(:planning_application) { @planning_application }
      should respond_with :success
      should render_template :show
      # should assign_to(:organisation) { @organisation }

      should "show entity name in title" do
        assert_select "title", /#{@planning_application.title}/
      end

      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
    
      # should "show api block" do
      #   assert_select "#api_info"
      # end
    end
    
    # context "with xml request" do
    #   setup do
    #     @planning_application.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
    #     get :show, :id => @planning_application.id, :format => "xml"
    #   end
    # 
    #   should assign_to(:entity) { @planning_application}
    #   should respond_with :success
    #   should_not render_with_layout
    #   should respond_with_content_type 'application/xml'
    #   # should "include suppliers" do
    #   #   assert_select "supplying-relationships>supplying-relationship>id", "#{@supplier.id}"
    #   # end
    #   # 
    #   # should "include supplying organisations" do
    #   #   assert_select "supplying-relationships>supplying-relationship>organisation>id", "#{@supplier.organisation.id}"
    #   # end
    # 
    # end
    # 
    # context "with json requested" do
    # 
    #   setup do
    #     @planning_application.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
    #     get :show, :id => @planning_application.id, :format => "json"
    #   end
    # 
    #   should assign_to(:entity) { @planning_application }
    #   should respond_with :success
    #   should_not render_with_layout
    #   should respond_with_content_type 'application/json'
    #   should "include supplying organisations" do
    #     # assert_match /supplying_relationships\":.+id\":#{@supplier.id}/, @response.body
    #   end
    # end

  end
  
end

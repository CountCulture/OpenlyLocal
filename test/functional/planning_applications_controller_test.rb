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

    # should "show PlanningApplication name in title" do
    #   assert_select "title", /#{@planning_application.title}/
    # end
  
    # should "show api block" do
    #   assert_select "#api_info"
    # end
  end
  
  context "on GET to :index" do
    setup do
      @postcode = Factory(:postcode, :code => 'AB12CD')
      @non_matching_application = Factory(:planning_application)
      @matching_application = Factory(:planning_application, :postcode => 'AB1 2CD')
    end
    
    context "and postcode not given" do
      setup do
        get :index
      end

      should "return message" do
        assert_select ".warning", :text => /postcode not found/i
      end
    end
    
    context "and postcode given" do
      
      should "find within 0.2km of lat long of postcode" do
        PlanningApplication.expects(:find).with(:all, :origin => [@postcode.lat, @postcode.lng], :within => 0.2, :order => 'created_at DESC', :limit => 20)
        get :index, :postcode => 'AB1 2CD'
      end

      context "and planning applications found" do
        setup do
          get :index, :postcode => 'AB1 2CD'
        end

        should assign_to(:planning_applications) { [@matching_application] }
        should respond_with :success
        should render_template :index
        should "list planning_applications" do
          assert_select "li a", @matching_application.title
        end

        should "show share block" do
          assert_select "#share_block"
        end

        should "show api block" do
          assert_select "#api_info"
        end

        should 'show title' do
          assert_select "title", /planning applications/i
          assert_select "title", /AB1 2CD/i
        end
      end
      
      context "and no postcode found" do
        setup do
          get :index, :postcode => 'XX1 2XX'
        end

        should "return message" do
          assert_select ".warning", :text => /postcode not found/i
        end
      end
      
      context "and no planning applications found" do
        setup do
          Factory(:postcode, :code => 'XX12XX')
          get :index, :postcode => 'XX1 2XX'
        end

        should respond_with :success

        should "return message" do
          assert_select ".warning", :text => /no matching planning applications/i
        end
      end
      
      context "with xml request" do
        setup do
          get :index, :postcode => 'AB1 2CD', :format => "xml"
        end

        should assign_to(:planning_applications) { PlanningApplication.find(:all) }
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/xml'
      end

      context "with json requested" do
        setup do
          get :index, :postcode => 'AB1 2CD', :format => "json"
        end

        should assign_to(:planning_applications) { PlanningApplication.find(:all) }
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/json'
      end
    end
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

      should "show PlanningApplication name in title" do
        assert_select "title", /#{@planning_application.title}/
      end

      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
      
      should "not show google map" do        
        assert_no_match /GBrowserIsCompatible/i, @response.body
      end
    
      # should "show api block" do
      #   assert_select "#api_info"
      # end
    end
    
    context "and planning_application has lat, lng" do
      setup do
        get :show, :id => Factory(:planning_application_with_lat_long).id
      end

      should "show google map" do
        assert_match /GBrowserIsCompatible/i, @response.body
      end
    end
    
    context "with xml request" do
      setup do
        @planning_application.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
        get :show, :id => @planning_application.id, :format => "xml"
      end
    
      should assign_to(:planning_application) { @planning_application}
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'    
    end
    
    context "with json requested" do
    
      setup do
        @planning_application.update_attribute(:address, "35 Some St, Anytown AN1 2NT")
        get :show, :id => @planning_application.id, :format => "json"
      end
    
      should assign_to(:planning_application) { @planning_application }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'
      should "include supplying organisations" do
      end
    end

  end
  
end

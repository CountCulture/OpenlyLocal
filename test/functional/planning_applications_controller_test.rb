require 'test_helper'

class PlanningApplicationsControllerTest < ActionController::TestCase

  should "route planning applications correctly to index with  true" do
    assert_routing("planning", {:controller => "planning_applications", :action => "overview"})
    assert_routing("planning_applications/1234", {:controller => "planning_applications", :action => "show", :id => '1234'})
    assert_routing("councils/42/planning_applications", {:controller => "planning_applications", :action => "index", :council_id => '42'})
    assert_routing("councils/42/planning_applications.rss", {:controller => "planning_applications", :action => "index", :council_id => '42', :format => 'rss'})
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
      @council = Factory(:generic_council)
      @matching_application = Factory(:planning_application_with_lat_long, :postcode => 'AB1 2CD', :council => @council, :retrieved_at => 10.days.ago)
      PlanningApplication.record_timestamps = false # update timestamp without triggering callbacks
      @another_matching_application = Factory(:planning_application_with_lat_long, :postcode => 'AB2 2CD', :updated_at => 5.days.ago, :created_at => 5.days.ago, :council => @council, :retrieved_at =>  5.days.ago)
      PlanningApplication.record_timestamps = true # update timestamp without triggering callbacks
    end
    
    context "and council_id given" do
      setup do
        get :index, :council_id => @council.id
      end
      
      should assign_to(:planning_applications)
      should respond_with :success
      should render_template :index
        
      should "list most recently updated planning applications first" do
        assert_equal [@matching_application, @another_matching_application], assigns(:planning_applications)
      end

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
        assert_select "title", /#{@council.name}/i
      end
      
      should "include rss feed link" do
        assert_select "link[rel='alternate'][type='application/rss+xml'][href='http://test.host/councils/#{@council.id}/planning_applications.rss']"
      end
    
      context "with rss requested" do
        setup do
          PlanningApplication.record_timestamps = true # update timestamp without triggering callbacks
          get :index, :council_id => @council.id, :format => "rss"
        end
      
        should respond_with :success
        # should_not render_with_layout
        should respond_with_content_type 'application/rss+xml'
        
        should "assign to planning_applications instance variable" do
          assert_equal [@matching_application, @another_matching_application], assigns(:planning_applications)
        end
        
        should "have title " do
          assert_select "title", "Latest Planning Applications in #{@council.name}"
        end
        
        should "list planning applications" do
          assert_select "item", 2 do
            assert_select "title", @matching_application.title
            assert_select "link", "http://test.host/planning_applications/#{@matching_application.to_param}"
            assert_match /georss:point>#{@matching_application.lat} #{@matching_application.lng}/, @response.body
          end
        end
      end

      
      context "with xml request" do
        setup do
          get :index, :council_id => @council.id, :format => "xml"
        end
  
        should assign_to(:planning_applications) { PlanningApplication.find(:all) }
        should respond_with :success
        # should_not render_with_layout
        should respond_with_content_type 'application/xml'
      end
  
      context "with json requested" do
        setup do
          get :index, :council_id => @council.id, :format => "json"
        end
  
        should assign_to(:planning_applications) { PlanningApplication.find(:all) }
        should respond_with :success
        # should_not render_with_layout
        should respond_with_content_type 'application/json'
      end
    end
    
    # context "and postcode not given" do
    #   setup do
    #     get :index
    #   end
    # 
    #   should "return message" do
    #     assert_select ".warning", :text => /postcode not found/i
    #   end
    # end
    
    # context "and postcode given" do
    #   
    #   should "find within 0.2km of lat long of postcode" do
    #     PlanningApplication.expects(:find).with(:all, :origin => [@postcode.lat, @postcode.lng], :within => 0.2, :order => 'created_at DESC', :limit => 20)
    #     get :index, :postcode => 'AB1 2CD'
    #   end
    # 
    #   context "and planning applications found" do
    #     setup do
    #       get :index, :postcode => 'AB1 2CD'
    #     end
    # 
    #     should assign_to(:planning_applications) { [@matching_application] }
    #     should respond_with :success
    #     should render_template :index
    #     should "list planning_applications" do
    #       assert_select "li a", @matching_application.title
    #     end
    # 
    #     should "show share block" do
    #       assert_select "#share_block"
    #     end
    # 
    #     should "show api block" do
    #       assert_select "#api_info"
    #     end
    # 
    #     should 'show title' do
    #       assert_select "title", /planning applications/i
    #       assert_select "title", /AB1 2CD/i
    #     end
    #   end
    #   
    #   context "and no postcode found" do
    #     setup do
    #       get :index, :postcode => 'XX1 2XX'
    #     end
    # 
    #     should "return message" do
    #       assert_select ".warning", :text => /postcode not found/i
    #     end
    #   end
    #   
    #   context "and no planning applications found" do
    #     setup do
    #       Factory(:postcode, :code => 'XX12XX')
    #       get :index, :postcode => 'XX1 2XX'
    #     end
    # 
    #     should respond_with :success
    # 
    #     should "return message" do
    #       assert_select ".warning", :text => /no matching planning applications/i
    #     end
    #   end
    #   
    #   context "with xml request" do
    #     setup do
    #       get :index, :postcode => 'AB1 2CD', :format => "xml"
    #     end
    # 
    #     should assign_to(:planning_applications) { PlanningApplication.find(:all) }
    #     should respond_with :success
    #     should_not render_with_layout
    #     should respond_with_content_type 'application/xml'
    #   end
    # 
    #   context "with json requested" do
    #     setup do
    #       get :index, :postcode => 'AB1 2CD', :format => "json"
    #     end
    # 
    #     should assign_to(:planning_applications) { PlanningApplication.find(:all) }
    #     should respond_with :success
    #     should_not render_with_layout
    #     should respond_with_content_type 'application/json'
    #   end
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

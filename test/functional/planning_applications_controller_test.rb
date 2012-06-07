require File.expand_path('../../test_helper', __FILE__)

class PlanningApplicationsControllerTest < ActionController::TestCase
  setup do
    Resque.stubs(:enqueue_to)
  end

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
      @matching_application = Factory(:planning_application_with_lat_long, :postcode => 'AB1 2CD', :council => @council, :retrieved_at => 5.days.ago, :start_date => 1.month.ago)
      PlanningApplication.record_timestamps = false # update timestamp without triggering callbacks
      @matching_application_without_details = Factory(:planning_application_with_lat_long, :postcode => 'AB3 2CD', :updated_at => 5.days.ago, :created_at => 5.days.ago, :council => @council)
      @another_matching_application = Factory(:planning_application_with_lat_long, :postcode => 'AB2 2CD', :updated_at => 5.days.ago, :created_at => 5.days.ago, :council => @council, :retrieved_at =>  5.days.ago, :start_date => 1.week.ago)
      PlanningApplication.record_timestamps = true # update timestamp without triggering callbacks
    end
    
    context "and council_id given" do
      context "in general" do
        setup do
          get :index, :council_id => @council.id
        end

        should assign_to(:planning_applications)
        should respond_with :success
        should render_template :index

        should "not include applications without detils most recently updated planning applications first" do
          assert !assigns(:planning_applications).include?(@matching_application_without_details)
          assert_equal 2, assigns(:planning_applications).size
        end

        should "list most planning applications with most recent start_date first" do
          assert_equal @another_matching_application, assigns(:planning_applications).first
        end

        should "list planning_applications" do
          assert_select "#planning_applications .planning_application"
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
      end
    
      context "with rss requested" do
        setup do
          PlanningApplication.record_timestamps = true # update timestamp without triggering callbacks
          get :index, :council_id => @council.id, :format => "rss"
        end
      
        should respond_with :success
        # should_not render_with_layout
        should respond_with_content_type 'application/rss+xml'
        
        should "list most planning applications with most recent updated_at first" do
          assert_equal @matching_application, assigns(:planning_applications).first
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

      context "when updated order requested" do
        setup do
          get :index, :council_id => @council.id, :order => 'updated'
        end

        should "list most planning applications with most recent updated_at first" do
          assert_equal @matching_application, assigns(:planning_applications).first
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

        should "include planning applications" do
          assert_select "planning-applications>planning-application>id"
        end

        should "not include council" do
          assert_select "planning-applications>planning-application>council>id", false
        end

        # should 'include pagination info' do
        #   assert_select "planning-applications>total-entries"
        # end
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

    context "and postcode given" do
      should "find within 0.2km of lat long of postcode" do
        PlanningApplication.expects(:find).with(:all, has_entries(:origin => [@postcode.lat, @postcode.lng], :within => 0.2))
        get :index, :postcode => 'AB1 2CD'
      end

      context "and planning applications found" do
        setup do
          PlanningApplication.stubs(:find).returns([@matching_application])
          
          get :index, :postcode => 'AB1 2CD'
        end

        should assign_to(:planning_applications) { [@matching_application] }
        should respond_with :success
        should render_template :index
        should "list planning_applications" do
          assert_select "#planning_applications .planning_application"
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
        context "with HTML requested" do
          setup do
            get :index, :postcode => 'XX1 2XX'
          end

          should "return message" do
            assert_select ".warning", :text => /postcode not found/i
          end
        end

        context "with XML requested" do
          setup do
            get :index, :postcode => 'XX1 2XX', :format => 'xml'
          end

          should_not assign_to(:planning_applications)
          # @note using +should respond_with_content_type 'application/xml'+ raises:
          #   NoMethodError: undefined method `content_type' for nil:NilClass

          # @note using +should respond_with :unprocessable_entity+ raises:
          #   NoMethodError: undefined method `response_code' for nil:NilClass
          should 'response with 422' do
            assert_response 422
          end
        end

        context "with JSON requested" do
          setup do
            get :index, :postcode => 'XX1 2XX', :format => 'json'
          end

          should_not assign_to(:planning_applications)
          # @note using +should respond_with_content_type 'application/xml'+ raises:
          #   NoMethodError: undefined method `content_type' for nil:NilClass

          # @note using +should respond_with :unprocessable_entity+ raises:
          #   NoMethodError: undefined method `response_code' for nil:NilClass
          should 'response with 422' do
            assert_response 422
          end
        end
      end

      context "and no planning applications found" do
        context "with HTML requested" do
          setup do
            get :index, :postcode => 'AB1 2CD'
          end

          should respond_with :success

          should "return message" do
            assert_select ".warning", :text => /no matching planning applications/i
          end
        end

        context "with XML requested" do
          def setup
            get :index, :postcode => 'AB1 2CD', :format => 'xml'
          end

          should_not assign_to(:planning_applications)
          # @note using +should respond_with_content_type 'application/xml'+ raises:
          #   NoMethodError: undefined method `content_type' for nil:NilClass

          # @note using +should respond_with :unprocessable_entity+ raises:
          #   NoMethodError: undefined method `response_code' for nil:NilClass
          should 'response with 422' do
            assert_response 422
          end
        end

        context "with JSON requested" do
          def setup
            get :index, :postcode => 'AB1 2CD', :format => 'json'
          end

          should_not assign_to(:planning_applications)
          # @note using +should respond_with_content_type 'application/xml'+ raises:
          #   NoMethodError: undefined method `content_type' for nil:NilClass

          # @note using +should respond_with :unprocessable_entity+ raises:
          #   NoMethodError: undefined method `response_code' for nil:NilClass
          should 'response with 422' do
            assert_response 422
          end
        end
      end

      context "with xml request" do
        setup do
          PlanningApplication.stubs(:find).returns([@matching_application])
          get :index, :postcode => 'AB1 2CD', :format => "xml"
        end
    
        should assign_to(:planning_applications) { PlanningApplication.find(:all) }
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/xml'
      end

      context "with json requested" do
        setup do
          PlanningApplication.stubs(:find).returns([@matching_application])
          get :index, :postcode => 'AB1 2CD', :format => "json"
        end
    
        should assign_to(:planning_applications) { PlanningApplication.find(:all) }
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/json'

        # should 'include pagination info' do
        #   assert_match %r(total_entries), @response.body
        #   assert_match %r(per_page), @response.body
        #   assert_match %r(page.+1), @response.body
        # end
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
    
      should assign_to(:planning_application) { @planning_application }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'
      
      should "include council" do
        assert_select "planning-application>council>id", "#{@planning_application.council.id}"
      end
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
      
      should "include council" do
        assert_match /planning_application\":.+council\":.+id\":#{@planning_application.council.id}/, @response.body
      end
    end

  end
  
  # admin tests
  context "on get to :admin planning_applications without auth" do
    setup do
      delete :admin
    end

    should respond_with 401
  end

  context "on get to :admin planning_applications" do
    setup do
      stub_authentication
      get :admin
    end

    should assign_to :councils
    should assign_to :latest_alert_subscribers
    should respond_with :success
    should render_template :admin
    should_not set_the_flash

  end
end

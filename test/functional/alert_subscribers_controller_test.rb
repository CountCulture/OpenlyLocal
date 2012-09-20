require File.expand_path('../../test_helper', __FILE__)

class AlertSubscribersControllerTest < ActionController::TestCase

  context "when routing to alert_subscribers" do
    should "have routing for confirm" do
      assert_routing("alert_subscribers/confirm", {:controller => "alert_subscribers", :action => "confirm"})
    end
    
    should "have routing for unsubscribing" do
      assert_routing("alert_subscribers/unsubscribe", {:controller => "alert_subscribers", :action => "unsubscribe"})
    end
    
    should "have routing for new" do
      assert_routing("alert_subscribers/new", {:controller => "alert_subscribers", :action => "new"})
    end
    
    should "have routing for creating" do
      assert_routing({ :method => 'post', :path => "alert_subscribers"}, {:controller => "alert_subscribers", :action => "create"})
    end
    # should "have routing for admin hyperlocal_sites" do
    #   assert_routing('/hyperlocal_sites/admin', {:controller => "hyperlocal_sites", :action => "admin"})
    # end
    
  end

  context "on GET to new" do
    context "when no defaults provided" do
      setup do
        get :new
      end

      should respond_with :success
      should render_template :new
      should_not set_the_flash
    end

    context "when default email provided" do
      setup do
        get :new, :email => 'example@example.com'
      end

      should "set default email" do
        assert_select '#alert_subscriber_email[value=?]', 'example@example.com'
      end
    end

    context "when default postcode provided" do
      setup do
        get :new, :postcode => 'foo'
      end

      should "set default postcode" do
        assert_select '#alert_subscriber_postcode_text[value=?]', 'foo'
      end
    end

    context "when default distance provided" do
      setup do
        get :new, :distance => 0.2
      end

      should "set default postcode" do
        assert_select '#alert_subscriber_distance_02[checked="checked"]'
      end
    end
  end

  context "on GET to confirm" do
    setup do
      @subscriber = Factory(:alert_subscriber, :email => 'foo@test.com')
    end
    
    context "when valid confirmation code and email submitted" do
      setup do
        get :confirm, :email => @subscriber.email, :confirmation_code => @subscriber.confirmation_code
      end

      should respond_with :redirect
      should redirect_to("the search page for the postcode"){{:controller => 'areas', :action => 'search', :postcode => @subscriber.postcode.code}}
      should set_the_flash.to(/subscription is active/)

      should "confirm subscriber" do
        assert @subscriber.reload.confirmed?
      end
    end
    
    context "when invalid confirmation code and email submitted" do
      setup do
        get :confirm, :email => @subscriber.email, :confirmation_code => 'foobar'
      end

      should respond_with :success
      should render_template :confirmed
      should_not set_the_flash

      should "not confirm subscriber" do
        assert !@subscriber.reload.confirmed?
      end
      
      should "return failure message" do
        assert_select '.alert', /unable to activate/i
      end
    end
    
  end
  
  context "on GET to unsubscribe" do
    setup do
      @subscriber = Factory(:alert_subscriber, :email => 'foo@test.com')
    end

    context "when valid unsubscribe token and email submitted" do
      setup do
        AlertSubscriber.expects(:unsubscribe_token).with(@subscriber.email).returns('foo1234567')
        get :unsubscribe, :email => @subscriber.email, :token => 'foo1234567'
      end

      should respond_with :success
      should render_template :unsubscribe
      should_not set_the_flash
      should "show success message" do
        assert_select '.alert', /success/i
      end
      
      should "destroy subscriber" do
        assert !AlertSubscriber.exists?(@subscriber)
      end
    end
    
    context "when invalid unsubscribe token and email submitted" do
      setup do
        AlertSubscriber.expects(:unsubscribe_token).with(@subscriber.email).returns('bar456')
        get :unsubscribe, :email => @subscriber.email, :token => 'foo1234567'
      end

      should respond_with :success
      should render_template :unsubscribe
      should_not set_the_flash
      
      should "show failure message" do
        assert_select '.alert', /fail/i
      end
      
      should "not destroy subscriber" do
        assert AlertSubscriber.exists?(@subscriber)
      end
    end
    
  end
  
  context "on POST to create" do
    context "and email is OK" do
      setup do
        @postcode = Factory(:postcode, :code => 'AB12CD')
        post :create, :alert_subscriber => {:email => 'new_user@test.com', :postcode_text => 'ab1 2cd'}
      end

      should assign_to :alert_subscriber
      should respond_with :success
      should render_template :subscribed
      
      should "create user" do
        assert AlertSubscriber.find_by_email('new_user@test.com')
      end

      should "associate user with postcode" do
        assert AlertSubscriber.find_by_email_and_postcode_id('new_user@test.com', @postcode.id)
      end

      should "not show errors" do
        assert_select "div.errorExplanation", false
      end

      should "set default distance" do
        assert_equal 0.2, AlertSubscriber.find_by_email('new_user@test.com').distance
      end
    end

    context "and distance is valid" do
      setup do
        @postcode = Factory(:postcode, :code => 'AB12CD')
        post :create, :alert_subscriber => {:email => 'new_user@test.com', :postcode_text => 'ab1 2cd', :distance => 0.8}
      end

      should assign_to :alert_subscriber
      should respond_with :success
      should render_template :subscribed

      should "create user" do
        assert AlertSubscriber.find_by_email('new_user@test.com')
      end
      
      should "associate user with postcode" do
        assert AlertSubscriber.find_by_email_and_postcode_id('new_user@test.com', @postcode.id)
      end
      
      should "not show errors" do
        assert_select "div.errorExplanation", false
      end

      should "set given distance" do
        assert_equal 0.8, AlertSubscriber.find_by_email('new_user@test.com').distance
      end
    end

    context "and distance is invalid" do
      setup do
        @old_subscriber_count = AlertSubscriber.count
        post :create, :alert_subscriber => {:email => 'new_user@test.com', :postcode_text => 'ab1 2cd', :distance => 200}
      end

      should "not create subscriber" do
        assert_equal @old_subscriber_count, AlertSubscriber.count
      end

      should assign_to :alert_subscriber
      should render_template :new

      should "show errors" do
        assert_select "div.errorExplanation"
      end
    end

    context "and subscriber with email already exists" do
      setup do
        @existing_subscriber = Factory(:alert_subscriber, :email => 'foo@test.com')
        @old_subscriber_count = AlertSubscriber.count
        post :create, :alert_subscriber => {:email => 'foo@test.com', :postcode_text => 'ab12cd'}
      end

      should "not create subscriber" do
        assert_equal @old_subscriber_count, AlertSubscriber.count
      end
      
      should assign_to :alert_subscriber
      should render_template :new
      
      should "show errors" do
        assert_select "div.errorExplanation"
      end
    end

  end
  
end

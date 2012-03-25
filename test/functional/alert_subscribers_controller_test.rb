require 'test_helper'

class AlertSubscribersControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  context "on GET to new" do
    setup do
      get :new
    end

    should respond_with :success
    should render_template :new
    should_not set_the_flash
  end

  context "on GET to confirm" do
    setup do
      @subscriber = Factory(:alert_subscriber, :email => 'foo@test.com')
    end
    
    context "when valid confirmation code and email submitted" do
      setup do
        get :confirm, :email => @subscriber.email, :confirmation_code => @subscriber.confirmation_code
      end

      should respond_with :success
      should render_template :confirmed
      should_not set_the_flash

      should "confirm subscriber" do
        assert @subscriber.reload.confirmed?
      end
      should "return success message" do
        assert_select '.alert', /success/i
      end
    end
    
    context "when invalid confirmation code and email submitted" do
      setup do
        get :confirm, :email => @subscriber.email, :confirmation_code => 'foobar'
      end

      should respond_with :success
      should render_template :confirmed

      should "not confirm subscriber" do
        assert !@subscriber.reload.confirmed?
      end
      
      should "return failure message" do
        assert_select '.alert', /fail/i
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
    context "in email is OK" do
      setup do
        @postcode = Factory(:postcode, :code => 'AB12CD')
        post :create, :email => 'new_user@test.com', :postcode => 'ab12cd'
      end

      should assign_to :alert_subscriber
      should respond_with :success
      should render_template :subscribed
      
      should "create user" do
        assert AlertSubscriber.find_by_email('new_user@test.com')
      end
      
      should "associate user with postcode" do
        assert AlertSubscriber.find_by_email_and_postcode('new_user@test.com', 'ab12cd')
      end
      
      should "not show errors" do
        assert_select "div.errorExplanation", false
      end
    end
    
    context "and subscriber with email already exists" do
      setup do
        @existing_subscriber = Factory(:alert_subscriber, :email => 'foo@test.com')
        @old_subscriber_count = AlertSubscriber.count
        post :create, :email => 'foo@test.com', :postcode => 'ab12cd'
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

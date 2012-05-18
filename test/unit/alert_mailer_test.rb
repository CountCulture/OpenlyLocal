require File.expand_path('../../test_helper', __FILE__)

class AlertMailerTest < ActionMailer::TestCase
  context "AlertMailer class" do
    setup do
      
    end

    should "override default smtp_settings" do
      p AlertMailer.smtp_settings
      assert_equal "alerts@openlylocal.com", AlertMailer.smtp_settings[:user_name]
    end
  end
  
  context "An AlertMailer planning_alert email" do
    setup do
      Resque.stubs(:enqueue_to)
      @planning_application = Factory(:planning_application_with_lat_long, :address => '22 Foo St, Bartown BT1 1TB', :postcode => 'BT1 1TB', :description => 'Some new development here')
      @alert_subscriber = Factory(:alert_subscriber)
      @report = AlertMailer.create_planning_alert(:subscriber => @alert_subscriber, :planning_application => @planning_application)
    end

    should "be sent from alerts@openlylocal.com" do
      assert_equal "alerts@openlylocal.com", @report.from[0]
    end
    
    should "be sent to alert_subscriber email address" do
      assert_equal @alert_subscriber.email, @report.to[0]
    end
    
    should "include address in subject" do
      assert_match /Planning Application/, @report.subject
      assert_match /22 Foo St/, @report.subject
    end
    
    should "include description and details in body" do
      assert_match /#{@planning_application.description}/, @report.body
    end
  end
  
  context "A AlertMailer confirmation email" do
    setup do
      Resque.stubs(:enqueue_to)
      @alert_subscriber = Factory(:alert_subscriber)
      @report = AlertMailer.create_confirmation(@alert_subscriber)
    end

    should "be sent from alerts@openlylocal.com" do
      assert_equal "alerts@openlylocal.com", @report.from[0]
    end
    
    should "be sent to alert_subscriber email address" do
      assert_equal @alert_subscriber.email, @report.to[0]
    end
    
    should "include appropriate subject" do
      assert_match /confirm/, @report.subject
    end
    
    should "include confirmation_link in body" do
      assert_match /#{@alert_subscriber.confirmation_code}/, @report.body
    end
  end
end

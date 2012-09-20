require File.expand_path('../../test_helper', __FILE__)

class AlertSubscriberTest < ActiveSupport::TestCase
  subject { @alert_subscriber }

  context "the AlertSubscriber class" do
    setup do
      @alert_subscriber = Factory(:alert_subscriber)
    end
  
    [:email, :postcode_text, :distance].each do |attribute|
      should validate_presence_of(attribute)
    end
    should validate_uniqueness_of :email
    [0.2, 0.8, 2].each do |value|
      should allow_value(value).for :distance
    end
    [0.0, 1.0].each do |value|
      should_not allow_value(value).for :distance
    end
    should belong_to :postcode
    %w(last_sent confirmed confirmation_code created_at updated_at postcode_id).each do |attribute|
      should_not allow_mass_assignment_of attribute
    end
    
    context "when confirming from email and confirmation code" do
      context "and email and confirmation code match" do

        should "return true" do
          assert AlertSubscriber.confirm_from_email_and_code(@alert_subscriber.email, @alert_subscriber.confirmation_code)
        end

        should "mark subscriber as confirmed" do
          AlertSubscriber.confirm_from_email_and_code(@alert_subscriber.email, @alert_subscriber.confirmation_code)
          assert @alert_subscriber.reload.confirmed
        end
      end
      
      context "and email and confirmation code do not match" do
        should "return false" do
          assert !AlertSubscriber.confirm_from_email_and_code(@alert_subscriber.email, 'another_code')
        end

        should "mark not subscriber as confirmed" do
          AlertSubscriber.confirm_from_email_and_code(@alert_subscriber.email, 'another_code')
          assert !@alert_subscriber.reload.confirmed
        end
      end
    end

    context 'on destruction' do
      setup do
        @alert_subscriber = Factory.build(:alert_subscriber)
      end

      should 'send unsubscribe confirmation email' do
        stub_email = stub 'unsubscribe_confirmation_email'
        AlertMailer.expects(:deliver_unsubscribe_confirmation!).with(@alert_subscriber)
        @alert_subscriber.destroy
      end
    end

    context "on creation" do
      setup do
        @postcode = Factory(:postcode)
        @alert_subscriber = Factory.build(:alert_subscriber)
      end

      should "create confirmation code" do
        assert_nil @alert_subscriber.confirmation_code
        @alert_subscriber.save!
        assert @alert_subscriber.reload.confirmation_code
      end
      
      should "set postcode from postcode_text" do
        Postcode.stubs(:find_from_messy_code).with(@alert_subscriber.postcode_text).returns(@postcode)
        @alert_subscriber.save!
        assert_equal @postcode, @alert_subscriber.reload.postcode
      end

      context 'with empty postcode' do
        setup do
          @alert_subscriber.postcode_text = nil
        end

        should 'fail to save subscriber' do
          assert @alert_subscriber.invalid?
          assert_match /can't be blank/, @alert_subscriber.errors.on(:postcode_id)
        end
      end

      context 'with no matching postcode' do
        setup do
          @alert_subscriber.postcode_text = 'XXX'
        end

        should 'fail to save subscriber' do
          assert @alert_subscriber.invalid?
          assert_match /can't be blank/, @alert_subscriber.errors.on(:postcode_id)
        end
      end

      should "send confirmation email" do
        stub_email= stub("confirmation_email")
        AlertMailer.expects(:deliver_confirmation!).with(@alert_subscriber)
        @alert_subscriber.save!
      end
    end
    
    context "when unsubscribing from email and unsubscribe token" do
      setup do
        AlertSubscriber.stubs(:unsubscribe_token).returns('foo12345')
      end

      should "get expected unsubscribe code for email address" do
        AlertSubscriber.expects(:unsubscribe_token).with(@alert_subscriber.email)
        AlertSubscriber.unsubscribe_user_from_email_and_token(@alert_subscriber.email, 'foo12345')
      end
      
      context "and given unsubscribe_code matches expected unsubscribe_code for email" do
        should 'destroy user' do
          AlertSubscriber.unsubscribe_user_from_email_and_token(@alert_subscriber.email, 'foo12345')
          assert !AlertSubscriber.exists?(@alert_subscriber.id)
        end
        
        should "return true" do
          assert AlertSubscriber.unsubscribe_user_from_email_and_token(@alert_subscriber.email, 'foo12345')
        end
      end

      context "and given unsubscribe_code does not expected unsubscribe_code for email" do
        should 'not destroy user' do
          AlertSubscriber.unsubscribe_user_from_email_and_token(@alert_subscriber.email, 'bar456')
          assert AlertSubscriber.exists?(@alert_subscriber.id)
        end
        
        should "return false" do
          assert !AlertSubscriber.unsubscribe_user_from_email_and_token(@alert_subscriber.email, 'bar456')
        end
      end
      
      context "and given email address is blank" do
        should 'not destroy user' do
          AlertSubscriber.expects(:unsubscribe_code).never
          AlertSubscriber.unsubscribe_user_from_email_and_token('       ', 'bar456')
        end
        
        should "return false" do
          assert !AlertSubscriber.unsubscribe_user_from_email_and_token('       ', 'bar456')
        end
      end
      
    end

    context "when generating unsubscribe token for email" do

      should "generate using SHA1 of SHA1s of email and unsubscribe key" do
        expected_token = Digest::SHA1.hexdigest( ['foo@test.com', UNSUBSCRIBE_SECRET_KEY].collect{|e| Digest::SHA1.hexdigest(e)}.join)
        
        assert_equal expected_token, AlertSubscriber.unsubscribe_token('foo@test.com')
      end
    end
  end
  
  context "an instance of the AlertSubscriber class" do
    setup do
      @alert_subscriber = Factory(:alert_subscriber)
      @planning_application = stub('planning_application')
    end

    context "when generating unsubscribe token for email" do

      should "generate using class method" do
        AlertSubscriber.expects(:unsubscribe_token).with(@alert_subscriber.email).returns('123456qwert')
        
        assert_equal '123456qwert', @alert_subscriber.unsubscribe_token()
      end
    end

    
    context "when sending planning alert" do

      should "send planning_application AlertMailer" do
        AlertMailer.expects(:deliver_planning_alert!).with(:subscriber => @alert_subscriber, :planning_application => @planning_application)
        @alert_subscriber.send_planning_alert(@planning_application)
      end
    end

  end
    
end
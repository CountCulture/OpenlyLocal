require 'test_helper'

class AlertSubscriberTest < ActiveSupport::TestCase
  subject { @alert_subscriber }

  context "the AlertSubscriber class" do
    setup do
      @alert_subscriber = Factory(:alert_subscriber)
    end
  
    should validate_presence_of :email
    should_validate_uniqueness_of :email
    should validate_presence_of :postcode

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
    
    context "on creation" do
      setup do
        @alert_subscriber = Factory.build(:alert_subscriber)
      end

      should "create confirmation code" do
        assert_nil @alert_subscriber.confirmation_code
        @alert_subscriber.save!
        assert @alert_subscriber.reload.confirmation_code
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
    end

    context "when generating unsubscribe token for email" do

      should "generate using class method" do
        AlertSubscriber.expects(:unsubscribe_token).with(@alert_subscriber.email).returns('123456qwert')
        
        assert_equal '123456qwert', @alert_subscriber.unsubscribe_token()
      end
    end
  end
    
end
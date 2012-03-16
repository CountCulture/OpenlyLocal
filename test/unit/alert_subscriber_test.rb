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

  end
end
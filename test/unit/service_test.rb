require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  subject { @service }
  context "The Service class" do
    setup do
      @service = Factory(:service)
    end
    should_validate_presence_of :category 
    should_validate_presence_of :lgsl
    should_validate_presence_of :lgil
    should_validate_presence_of :service_name
    should_validate_presence_of :authority_level
    should_validate_presence_of :url
  end
end

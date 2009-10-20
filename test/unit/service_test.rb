require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  subject { @service }
  context "The Service class" do
    setup do
      @service = Factory(:service) # category 'Foo 1'
    end
    should_validate_presence_of :category 
    should_validate_presence_of :lgsl
    should_validate_presence_of :lgil
    should_validate_presence_of :service_name
    should_validate_presence_of :authority_level
    should_validate_presence_of :url
    
    should "alias service_name as title" do
      assert_equal @service.service_name, @service.title
    end
    
    should "build url for service given council" do
      @council = Factory(:council, :ldg_id => 42)
      expected_url = "http://local.direct.gov.uk/LDGRedirect/index.jsp?LGSL=31&LGIL=47&AgencyId=42&Type=Single"
      assert_equal expected_url, Service.new(:lgsl => 31, :lgil => 47).url_for(@council)
    end
  end
end

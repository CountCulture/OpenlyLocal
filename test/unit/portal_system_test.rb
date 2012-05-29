require File.expand_path('../../test_helper', __FILE__)

class PortalSystemTest < ActiveSupport::TestCase
  
  context "The PortalSystem class" do
    setup do
      @existing_portal = Factory.create(:portal_system)
    end
    
    should validate_presence_of :name
    should validate_uniqueness_of :name
    should have_many :councils
    should have_many :parsers
  end
  
  context "A PortalSystem instance" do
    setup do
      @existing_portal = Factory.create(:portal_system)
    end

    should "alias name as title" do
      assert_equal @existing_portal.name, @existing_portal.title
    end
  end
  
end

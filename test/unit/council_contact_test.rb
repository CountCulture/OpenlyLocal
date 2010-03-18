require 'test_helper'

class CouncilContactTest < ActiveSupport::TestCase
  context "The CouncilContact class" do
    setup do
      @officer = Factory(:council_contact)
    end
    
    should_belong_to :council 
    should_validate_presence_of :name
    should_validate_presence_of :position
    should_validate_presence_of :email
    should_validate_presence_of :council_id
  end
end
